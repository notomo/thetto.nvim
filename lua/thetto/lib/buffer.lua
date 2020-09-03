local M = {}

M.scratch = function(modify)
  local bufnr = vim.api.nvim_create_buf(false, true)
  modify(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  return bufnr
end

return M
