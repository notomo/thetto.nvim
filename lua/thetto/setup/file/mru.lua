local paths = require("thetto/lib/_persist")("setup/file/mru")

local M = {}

M.limit = 100

local group_name = "thetto_setup_file_mru"

M.start = function()
  vim.api.nvim_command(("augroup %s"):format(group_name))
  vim.api.nvim_command("autocmd!")
  local on_buf_enter = ("autocmd %s BufEnter * lua require('thetto/setup/file/mru')._add(vim.fn.expand('<abuf>'))"):format(group_name)
  vim.api.nvim_command(on_buf_enter)
  vim.api.nvim_command("augroup END")
end

M.get = function()
  return vim.fn.reverse(paths)
end

M._add = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return
  end
  if vim.tbl_contains(paths, path) then
    return
  end

  if #paths > M.limit then
    table.remove(paths, 1)
  end
  table.insert(paths, path)
end

return M
