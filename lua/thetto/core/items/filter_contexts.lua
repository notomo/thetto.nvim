local M = {}
M.__index = M

function M.new(ignorecase, smartcase, input_lines)
  return vim.tbl_map(function(input_line)
    return M._new_one(ignorecase, smartcase, input_line)
  end, input_lines)
end

function M._new_one(ignorecase, smartcase, input_line)
  if not ignorecase and smartcase and input_line:find("[A-Z]") then
    ignorecase = false
  else
    ignorecase = true
  end
  return {
    ignorecase = ignorecase,
    input_line = input_line,
  }
end

return M
