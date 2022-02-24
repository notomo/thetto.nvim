local M = {}
M.__index = M

function M.new(ignorecase, smartcase, input_lines)
  if not ignorecase and smartcase and table.concat(input_lines, ""):find("[A-Z]") then
    ignorecase = false
  else
    ignorecase = true
  end
  return {
    ignorecase = ignorecase,
  }
end

return M
