local M = {}
M.__index = M

function M.new(inputs, need_source_invalidation)
  local tbl = {
    inputs = inputs,
    need_source_invalidation = need_source_invalidation or false,
  }
  return setmetatable(tbl, M)
end

return M
