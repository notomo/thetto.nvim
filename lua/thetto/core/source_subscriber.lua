local M = {}

function M.new(source, source_ctx)
  local result = source.collect(source_ctx)
  if type(result) == "string" then
    local err = result
    local source_errored = true
    return function(observer)
      observer:error(err)
    end, source_errored
  end

  local subscriber = M._new(result)
  local source_filter = source.filter
  if not source_filter then
    return subscriber
  end

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  return function(observer)
    local subscription = observable:subscribe({
      next = function(...)
        observer:next(source_filter(...))
      end,
      complete = function()
        observer:complete()
      end,
      error = function(...)
        observer:error(...)
      end,
    })
    return function()
      subscription:unsubscribe()
    end
  end
end

function M._new(result)
  if type(result) == "function" then
    local subscriber = result
    return subscriber
  end

  if require("thetto.lib.async").is_task(result) then
    local task = result
    return function(observer)
      --- @async
      --- @return nil
      local consume = function()
        local resolved = vim.async.await(task)
        if type(resolved) == "function" then
          -- task returns subscriber case
          resolved(observer)
          return
        end

        -- task returns items case
        observer:next(resolved)
        observer:complete()
      end

      local cancel = require("thetto.lib.async").observe(observer, consume)
      return function()
        -- WHY: closing the source task first resumes the consumer with "closed" and
        -- reports the unsubscribe as a source error
        -- NOT: task:close() before cancel()
        cancel()
        task:close()
      end
    end
  end

  local items = result
  return function(observer)
    observer:next(items)
    observer:complete()
  end
end

return M
