local M = {}

function M.new(kinds)
  local tbl = {}
  return setmetatable(tbl, M)
end

return M
