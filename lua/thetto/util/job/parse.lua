local M = {}

M.output = function(output)
  return vim.split(output, "\n", { plain = true, trimempty = true })
end

return M
