local persist = require("thetto/core/persist")

local M = {}

M.add = function(key, values)
  local current = persist[key] or {}
  for k, v in pairs(values) do
    current[k] = v
  end
  current.updated_at = vim.fn.reltimestr(vim.fn.reltime())
  persist[key] = current
end

M.get = function(key)
  return persist[key] or {}
end

M.recent = function()
  local recent = nil
  local recent_time = 0
  for _, ctx in pairs(persist) do
    local time = tonumber(ctx.updated_at)
    if recent_time < time then
      recent = ctx
      recent_time = time
    end
  end
  return recent
end

M.delete = function(key)
  persist[key] = nil
end

return M
