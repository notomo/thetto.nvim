local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[thetto] " .. err .. "\n")
end

return M
