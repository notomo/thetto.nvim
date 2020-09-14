local paths = require("thetto/lib/_persist")("setup/file/mru")
local listlib = require("thetto/lib/list")
local pathlib = require("thetto/lib/path")
local filelib = require("thetto/lib/file")

local M = {}

M.limit = 100
M.ignore_pattern = "^$"

local store_file_path = pathlib.user_data_path("setup_file_mru.txt")
local group_name = "thetto_setup_file_mru"

M.start = function()
  local stored_paths = filelib.read_lines(store_file_path, 0, M.limit)
  paths = vim.tbl_filter(M.validate_fn, stored_paths)

  vim.api.nvim_command(("augroup %s"):format(group_name))
  vim.api.nvim_command("autocmd!")
  local on_buf_enter = ("autocmd %s BufEnter * lua require('thetto/setup/file/mru')._add(vim.fn.expand('<abuf>'))"):format(group_name)
  vim.api.nvim_command(on_buf_enter)
  local on_quit_pre = ("autocmd %s QuitPre * lua require('thetto/setup/file/mru')._save()"):format(group_name)
  vim.api.nvim_command(on_quit_pre)
  vim.api.nvim_command("augroup END")
end

M.get = function()
  return vim.fn.reverse(paths)
end

M.validate_fn = function()
  local regex = vim.regex(M.ignore_pattern)
  return function(line)
    return not regex:match_str(line) and filelib.readable(line)
  end
end

M._add = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return
  end

  local is_valid = M.validate_fn()
  if not is_valid(path) then
    return
  end

  local removed = listlib.remove(paths, path)
  if not removed and #paths > M.limit then
    table.remove(paths, 1)
  end

  table.insert(paths, path)
end

M._save = function()
  filelib.write_lines(store_file_path, M.get())
end

return M
