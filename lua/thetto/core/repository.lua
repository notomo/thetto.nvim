local persist = require("thetto/lib/_persist")

local M = {}

M.set = function(key, values)
  local new_values = {}
  for k, v in pairs(values) do
    new_values[k] = v
  end
  new_values._updated_at = vim.fn.reltimestr(vim.fn.reltime())
  persist[key] = new_values
end

M.get = function(key)
  return persist[key] or {}
end

M.resume = function(key)
  if key ~= nil then
    local ctx = persist[key]
    if ctx == nil then
      return nil, "not found state for resume by: " .. key
    end
    return ctx, nil
  end

  local recent = nil
  local recent_time = 0
  for _, ctx in pairs(persist) do
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

M.get_from_path = function(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  -- this should move to the view module maybe
  local key = path:match("thetto://(.+)/thetto")
  if key == nil then
    return nil, "not matched path: " .. path
  end

  local ctx = M.get(key)
  if vim.tbl_isempty(ctx) then
    return nil, "empty"
  end

  return ctx, nil
end

M.delete = function(key)
  persist[key] = nil
end

return M
