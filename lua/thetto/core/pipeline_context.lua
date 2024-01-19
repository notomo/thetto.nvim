local M = {}
M.__index = M

function M.new(inputs, source_input)
  local tbl = {
    inputs = inputs,
    source_input = source_input,
  }
  return setmetatable(tbl, M)
end

return M
