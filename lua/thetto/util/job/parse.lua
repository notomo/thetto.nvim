local M = {}

function M.output(output)
  return vim.split(output, "\n", { plain = true, trimempty = true })
end

return M
