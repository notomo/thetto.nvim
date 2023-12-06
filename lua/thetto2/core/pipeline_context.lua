local M = {}
M.__index = M

function M.new(inputs)
  local tbl = {
    inputs = inputs or {},
  }
  return setmetatable(tbl, M)
end

return M
