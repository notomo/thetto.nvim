local repository = require("thetto.lib.repository").Repository.new("context")

local M = {}

local Context = {}
Context.__index = Context
M.Context = Context

function Context.new(source_name, collector, ui, executor)
  local tbl = {
    collector = collector,
    ui = ui,
    executor = executor,
    _updated_at = vim.fn.reltimestr(vim.fn.reltime()),
  }
  local self = setmetatable(tbl, Context)
  repository:set(source_name, self)
  return self
end

function Context.get(source_name)
  vim.validate({ source_name = { source_name, "string", true } })

  if not source_name then
    return nil, "no source_name"
  end

  local ctx = repository:get(source_name)
  if not ctx then
    return nil, "no context: " .. source_name
  end
  return ctx, nil
end

function Context.get_from_path(bufnr, pattern)
  vim.validate({ bufnr = { bufnr, "number", true }, pattern = { pattern, "string", true } })
  bufnr = bufnr or 0
  pattern = pattern or ""

  local path = vim.api.nvim_buf_get_name(bufnr)
  local source_name = path:match("^thetto://(.+)/thetto" .. pattern)
  if not source_name then
    return nil, "not matched path: " .. path
  end

  return Context.get(source_name)
end

function Context.resume(source_name)
  if source_name ~= nil then
    local ctx, err = Context.get(source_name)
    if err then
      return nil, err
    end
    return ctx, nil
  end

  local recent = nil
  local recent_time = 0
  for _, ctx in repository:all() do
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
  for _, ctx in repository:all() do
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
  for _, ctx in repository:all() do
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

function Context.resume_last()
  local all = {}
  for _, ctx in repository:all() do
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
  return repository:all()
end

return M
