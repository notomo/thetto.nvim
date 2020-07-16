local M = {}

M.root = vim.fn.getcwd()

M.command = function(cmd)
  vim.api.nvim_command(cmd)
end

local waiting = false

M.before_each = function()
  M.command("filetype on")
  M.command("syntax enable")
  waiting = false
  require("thetto/thetto")._changed_after = function()
    waiting = true
  end
end

M.after_each = function()
  M.command("tabedit")
  M.command("tabonly!")
  M.command("silent! %bwipeout!")
  M.command("filetype off")
  M.command("syntax off")
  print(" ")

  -- NOTE: for require("test.helper")
  vim.api.nvim_set_current_dir(M.root)
end

M.set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

M.sync_input = function(texts)
  vim.api.nvim_put(texts, "c", true, true)
  local ok = vim.wait(1000, function()
    return waiting
  end, 10)
  waiting = false
  if not ok then
    assert(false, "wait timeout")
  end
end

M.search = function(pattern)
  local result = vim.fn.search(pattern)
  if result == 0 then
    local msg = string.format("%s not found", pattern)
    assert(false, msg)
  end
  return result
end

local assert = require("luassert")
local AM = {}

AM.window_count = function(expected)
  local actual = vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
  local msg = string.format("window count should be %s, but actual: %s", expected, actual)
  assert.equals(expected, actual, msg)
end

AM.current_line = function(expected)
  local actual = vim.fn.getline(".")
  local msg = string.format("current line should be %s, but actual: %s", expected, actual)
  assert.equals(expected, actual, msg)
end

AM.exists_pattern = function(pattern)
  local result = vim.fn.search(pattern, "n")
  if result == 0 then
    local msg = ("`%s` not found"):format(pattern)
    assert(false, msg)
  end
end

AM.not_exists_pattern = function(pattern)
  local result = vim.fn.search(pattern, "n")
  if result ~= 0 then
    local msg = ("`%s` found"):format(pattern)
    assert(false, msg)
  end
end

AM.file_name = function(expected)
  local actual = vim.fn.fnamemodify(vim.fn.bufname("%"), ":t")
  local msg = ("file name should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.filetype = function(expected)
  local actual = vim.bo.filetype
  local msg = ("buffer &filetype should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.current_dir = function(expected)
  local actual = vim.fn.getcwd()
  local msg = ("current dir should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

M.assert = AM

return M
