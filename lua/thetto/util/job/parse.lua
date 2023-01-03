local M = {}

M.output = function(output)
  return vim.split(output, "\n", { plain = true })
end

return M
