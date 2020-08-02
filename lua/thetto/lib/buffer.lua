local M = {}

M.force_create = function(name, modify)
  local pattern = ("^%s$"):format(name)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr ~= -1 then
    vim.api.nvim_command(bufnr .. "bwipeout!")
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  modify(bufnr)
  return bufnr
end

M.find_var = function(bufnr, name)
  local ok, var = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if not ok then
    return nil
  end
  return var
end

return M
