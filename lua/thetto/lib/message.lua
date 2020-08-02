local M = {}

M.error = function(err)
  vim.api.nvim_err_write(err .. "\n")
end

return M
