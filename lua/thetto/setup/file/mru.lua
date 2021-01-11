local persist = {paths = {}}
local listlib = require("thetto/lib/list")
local pathlib = require("thetto/lib/path")
local filelib = require("thetto/lib/file")
local vim = vim

local M = {}

M.limit = 500
M.ignore_pattern = "^$"

local store_file_path = pathlib.user_data_path("setup_file_mru.txt")
local group_name = "thetto_setup_file_mru"

M.start = function()
  local stored_paths = filelib.read_lines(store_file_path, 0, M.limit)
  persist.paths = vim.tbl_filter(M.validate_fn, stored_paths)

  vim.cmd(("augroup %s"):format(group_name))
  vim.cmd("autocmd!")
  local on_buf_enter = ("autocmd %s BufEnter * lua require('thetto/setup/file/mru')._add(vim.fn.expand('<abuf>'))"):format(group_name)
  vim.cmd(on_buf_enter)
  local on_quit_pre = ("autocmd %s QuitPre * lua require('thetto/setup/file/mru')._save()"):format(group_name)
  vim.cmd(on_quit_pre)
  vim.cmd("augroup END")
end

M.get = function()
  return vim.fn.reverse(persist.paths)
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

  local removed = listlib.remove(persist.paths, path)
  if not removed and #persist.paths > M.limit then
    table.remove(persist.paths, 1)
  end

  table.insert(persist.paths, path)
end

M._save = function()
  filelib.write_lines(store_file_path, persist.paths)
end

return M
