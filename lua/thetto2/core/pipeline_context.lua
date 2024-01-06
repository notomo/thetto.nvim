local M = {}
M.__index = M

function M.new(inputs, source_input, is_interactive)
  local tbl = {
    inputs = inputs,
    source_input = source_input,
    is_interactive = is_interactive,
  }
  return setmetatable(tbl, M)
end

return M
