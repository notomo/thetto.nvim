local persist = require("thetto/core/persist")

local M = {}

M.add = function(key, values)
  local current = persist[key] or {}
  for k, v in pairs(values) do
    current[k] = v
  end
  persist[key] = current
end

M.get = function(key)
  return persist[key] or {}
end

M.delete = function(key)
  persist[key] = nil
end

return M
