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
  require("thetto/core/engine")._changed_after = function()
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

  require("thetto/cleanup")("thetto")
end

M.buffer_log = function()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

M.set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

M.sync_input = function(texts)
  waiting = false
  vim.api.nvim_put(texts, "c", true, true)
  local ok = vim.wait(1000, function()
    return waiting
  end, 10)
  waiting = false
  if not ok then
    assert(false, "wait timeout")
  end
end

M.sync_open = function(...)
  waiting = false
  local job = require("thetto/entrypoint/command").open(...)
  if job == nil then
    return
  end
  local ok = job:wait(1000)
  if not ok then
    assert(false, "job wait timeout")
  end
  ok = vim.wait(1000, function()
    return waiting
  end, 10)
  waiting = false
  if not ok then
    assert(false, "wait timeout")
  end
end

M.sync_execute = function(...)
  local job = require("thetto/entrypoint/command").execute(...)
  if job == nil then
    return
  end
  local ok = job:wait(1000)
  if not ok then
    assert(false, "job wait timeout")
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
local AM = assert

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

AM.not_current_dir = function(expected)
  local actual = vim.fn.getcwd()
  local msg = ("current dir should be %s, but actual: %s"):format(expected, actual)
  assert.are_not.equals(expected, actual, msg)
end

AM.exists_message = function(expected)
  local messages = vim.split(vim.api.nvim_exec("messages", true), "\n")
  for _, msg in ipairs(messages) do
    if msg:match(expected) then
      return
    end
  end
  assert(false, "not found message: " .. expected)
end

AM.tab_count = function(expected)
  local actual = vim.fn.tabpagenr("$")
  local msg = ("tab count should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.error_message = function(expected, f)
  local ok, actual = pcall(f)
  if ok then
    assert(false, "should be error")
  end
  local msg = ("error message should end with '%s', but actual: '%s'"):format(expected, actual)
  assert.is_true(vim.endswith(actual, expected), msg)
end

AM.completion_contains = function(result, expected)
  local names = vim.split(result, "\n", true)
  for _, name in ipairs(names) do
    if name == expected then
      return
    end
  end
  local msg = ("completion should contain \"%s\", but actual: %s"):format(expected, vim.inspect(names))
  assert(false, msg)
end

AM.virtual_text = function(expected)
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line(".") - 1
  local chunk = vim.api.nvim_buf_get_virtual_text(bufnr, line)[1]
  if chunk == nil then
    assert(false, ("expected virtual text \"%s\" is not found"):format(expected))
  end
  local actual = chunk[1]
  local msg = ("virtual text should be %s, but actual: %s"):format(expected, actual)
  assert.equals(expected, actual, msg)
end

AM.register = function(name, expected)
  local actual = vim.fn.getreg(name)
  local msg = ("%s register should be %s, but actual: %s"):format(name, expected, actual)
  assert.equals(expected, actual, msg)
end

M.assert = AM

return M
