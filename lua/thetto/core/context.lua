local _contexts = {}

local Context = {}
Context.__index = Context

local vim = vim

local now = function()
  return vim.fn.reltimestr(vim.fn.reltime())
end

function Context.new(source_name, collector, ui, executor, can_resume)
  local tbl = {
    collector = collector,
    ui = ui,
    executor = executor,
    _updated_at = now(),
    _can_resume = can_resume,
  }
  local self = setmetatable(tbl, Context)
  _contexts[source_name] = self
  return self
end

function Context.get(source_name)
  vim.validate({ source_name = { source_name, "string", true } })

  if not source_name then
    return nil, "no source_name"
  end

  local ctx = _contexts[source_name]
  if not ctx then
    return nil, "no context: " .. source_name
  end
  return ctx, nil
end

local api = vim.api

function Context.get_from_path(bufnr, pattern)
  vim.validate({ bufnr = { bufnr, "number", true }, pattern = { pattern, "string", true } })
  bufnr = bufnr or api.nvim_get_current_buf()
  pattern = pattern or ""

  if not api.nvim_buf_is_valid(bufnr) then
    return nil, "invalid buffer: " .. bufnr
  end

  local path = api.nvim_buf_get_name(bufnr)
  local source_name = path:match("^thetto://(.+)/thetto" .. pattern)
  if not source_name then
    return nil, "not found state in: " .. path
  end

  local ctx, err = Context.get(source_name)
  if err then
    return nil, ("buffer=%d: %s"):format(bufnr, err)
  end
  return ctx, nil
end

local resume_candidates = function()
  local ctxs = {}
  for _, ctx in pairs(_contexts) do
    if ctx._can_resume then
      table.insert(ctxs, ctx)
    end
  end
  return ipairs(ctxs)
end

function Context.resume(source_name)
  if source_name ~= nil then
    local ctx, err = Context.get(source_name)
    if err then
      return nil, err
    end
    if not ctx._can_resume then
      return nil, "no context that can resume: " .. source_name
    end
    return ctx, nil
  end

  local recent = nil
  local recent_time = 0
  for _, ctx in resume_candidates() do
    local time = tonumber(ctx._updated_at)
    if recent_time < time then
      recent = ctx
      recent_time = time
    end
  end

  if recent == nil then
    return nil, "not found state for resume"
  end
  return recent, nil
end

function Context.resume_previous(self)
  local resumed = nil
  local at = 0
  local max_at = tonumber(self._updated_at)
  for _, ctx in resume_candidates() do
    local updated_at = tonumber(ctx._updated_at)
    if at < updated_at and updated_at < max_at then
      resumed = ctx
      at = updated_at
    end
  end
  if not resumed then
    return nil, "not found state for resume"
  end
  return resumed, nil
end

function Context.resume_next(self)
  local resumed = nil
  local min_at = tonumber(self._updated_at)
  local at = min_at
  for _, ctx in resume_candidates() do
    local updated_at = tonumber(ctx._updated_at)
    if min_at <= at and at < updated_at then
      resumed = ctx
      at = updated_at
    end
  end
  if not resumed then
    return nil, "not found state for resume"
  end
  return resumed, nil
end

function Context.on_close(self)
  self._updated_at = now()
end

function Context.resume_last()
  local all = {}
  for _, ctx in resume_candidates() do
    table.insert(all, ctx)
  end
  table.sort(all, function(a, b)
    return a._updated_at < b._updated_at
  end)
  local resumed = all[1]
  if not resumed then
    return nil, "not found state for resume"
  end
  return resumed, nil
end

function Context.all()
  return pairs(_contexts)
end

return Context
