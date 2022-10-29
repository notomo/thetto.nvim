local M = {}

M.output = function(output)
  return vim.split(output, "\n", true)
end

return M
