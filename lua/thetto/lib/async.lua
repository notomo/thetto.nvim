local M = {}

--- @param value any
--- @return boolean # whether the value is a vim.async.Task
function M.is_task(value)
  return type(value) == "table" and type(value.pwait) == "function"
end

--- @async
--- @param value any
--- @return any # the task result if the value is a task, the value itself otherwise
function M.await_value(value)
  if M.is_task(value) then
    return vim.async.await(value)
  end
  return value
end

--- @async
--- @param fs (async fun(): any)[] run concurrently
--- @return any[] # the values in the given order, raising the first error
function M.all(fs)
  local tasks = vim
    .iter(fs)
    :map(function(f)
      -- WHY: a child task that fails closes its siblings, while Promise.all
      -- left the other promises running
      -- NOT: vim.async.run(f) without detaching it
      return vim.async.run(f):detach()
    end)
    :totable()

  local values = {}
  for i, task in ipairs(tasks) do
    values[i] = vim.async.await(task)
  end
  return values
end

--- @async
--- @param fs (async fun(): any)[] run concurrently
--- @return { ok: boolean, value: any }[] # the results in the given order, raising nothing
function M.all_settled(fs)
  local tasks = vim
    .iter(fs)
    :map(function(f)
      -- WHY: the failure of an attached child fails this task too, so the first
      -- one would close the rest instead of letting them settle
      -- NOT: vim.async.run(f) without detaching it
      return vim.async.run(f):detach()
    end)
    :totable()

  local results = {}
  for i, task in ipairs(tasks) do
    local ok, value = vim.async.pawait(task)
    results[i] = { ok = ok, value = value }
  end
  return results
end

--- @return vim.async.Task # settled by the returned functions
--- @return fun(value: any?) resolve
--- @return fun(err: any) reject
function M.with_resolvers()
  local settle
  local pending

  --- @async
  local wait_settled = function()
    local err, value = vim.async.await(function(callback)
      -- WHY: a task created inside a running task does not start until the parent reaches
      -- its next checkpoint, so the settled result can arrive before this callback runs
      -- NOT: assuming settle is assigned by the time resolve() is called
      if pending then
        return callback(pending[1], pending[2])
      end
      settle = callback
    end)
    if err then
      error(err, 0)
    end
    return M.await_value(value)
  end
  local task = vim.async.run(wait_settled)

  local finish = function(err, value)
    -- WHY: consumer handlers are vim.schedule_wrap-ed, so settling in the same tick
    -- completes the task before they redraw, which promise.nvim never did
    -- NOT: calling settle() directly
    vim.schedule(function()
      if settle then
        return settle(err, value)
      end
      pending = { err, value }
    end)
  end
  local resolve = function(value)
    finish(nil, value)
  end
  local reject = function(err)
    finish(err)
  end
  return task, resolve, reject
end

--- @param observer table takes the failure of f
--- @param f async fun()
--- @return fun() cancel
function M.observe(observer, f)
  --- @async
  --- @return nil
  local run = function()
    local ok, err = pcall(f)
    if not ok and not vim.async.is_closing() then
      observer:error(err)
    end
  end

  local task = vim.async.run(run)
  return function()
    task:close()
  end
end

--- @param cancel fun()
--- @return vim.async.Closable # closed on task cancellation
function M.closable(cancel)
  return {
    close = function(_, callback)
      cancel()
      if callback then
        callback()
      end
    end,
  }
end

return M
