local M = {}

M.root = vim.fn.getcwd()

M.test_data_dir = M.root .. "/test/test_data/"

M.command = function(cmd)
  local _, err = pcall(vim.api.nvim_command, cmd)
  if err then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local msg = ("on %s: failed excmd `%s`\n%s"):format(pos, cmd, err)
    error(msg)
  end
end

local waiting = false

M.before_each = function()
  M.command("filetype on")
  M.command("syntax enable")
  waiting = false
  require("thetto/core/engine")._changed_after = function()
    waiting = true
  end
  M.new_directory("")
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

  require("thetto/lib/module").cleanup("thetto")
  M.delete("")
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
  local job = require("thetto/entrypoint/command").open({...})
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
  local job = require("thetto/entrypoint/command").execute(0, {8888, 8888}, {...})
  if job == nil then
    return
  end
  local ok = job:wait(1000)
  if not ok then
    assert(false, "job wait timeout")
  end
end

M.wait_ui = function()
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
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local lines = table.concat(vim.fn.getbufline("%", 1, "$"), "\n")
    local msg = ("on %s: `%s` not found in buffer:\n%s"):format(pos, pattern, lines)
    assert(false, msg)
  end
  return result
end

M.new_file = function(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({...}) do
    f:write(line .. "\n")
  end
  f:close()
end

M.new_directory = function(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

M.delete = function(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

local vassert = require("vusted.assert")
local asserts = vassert.asserts
M.assert = vassert.assert

asserts.create("window_count"):register_eq(function()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end)

asserts.create("current_line"):register_eq(function()
  return vim.fn.getline(".")
end)

asserts.create("register_value"):register_eq(function(name)
  return vim.fn.getreg(name)
end)

asserts.create("line_count"):register_eq(function()
  return vim.api.nvim_buf_line_count(0)
end)

asserts.create("current_window"):register_eq(function()
  return vim.api.nvim_get_current_win()
end)

asserts.create("current_column"):register_eq(function()
  return vim.fn.col(".")
end)

asserts.create("tab_count"):register_eq(function()
  return vim.fn.tabpagenr("$")
end)

asserts.create("file_name"):register_eq(function()
  return vim.fn.fnamemodify(vim.fn.bufname("%"), ":t")
end)

asserts.create("filetype"):register_eq(function()
  return vim.bo.filetype
end)

asserts.create("current_dir"):register_eq(function()
  return vim.fn.getcwd()
end)

asserts.create("exists_pattern"):register(function(self)
  return function(_, args)
    local pattern = args[1]
    local result = vim.fn.search(pattern, "n")
    self:set_positive(("`%s` not found"):format(pattern))
    self:set_negative(("`%s` found"):format(pattern))
    return result ~= 0
  end
end)

asserts.create("exists_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    self:set_positive(("`%s` not found message"):format(expected))
    self:set_negative(("`%s` found message"):format(expected))
    local messages = vim.split(vim.api.nvim_exec("messages", true), "\n")
    for _, msg in ipairs(messages) do
      if msg:match(expected) then
        return true
      end
    end
    return false
  end
end)

asserts.create("error_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    local f = args[2]
    local ok, actual = pcall(f)
    if ok then
      self:set_positive("should be error")
      self:set_negative("should be error")
      return false
    end
    self:set_positive(("error message should end with '%s', but actual: '%s'"):format(expected, actual))
    self:set_negative(("error message should not end with '%s', but actual: '%s'"):format(expected, actual))
    return vim.endswith(actual, expected)
  end
end)

asserts.create("completion_contains"):register(function(self)
  return function(_, args)
    local result = args[1]
    local expected = args[2]
    local names = vim.split(result, "\n", true)
    self:set_positive(("completion should contain \"%s\", but actual: %s"):format(expected, vim.inspect(names)))
    self:set_negative(("completion should not contain \"%s\", but actual: %s"):format(expected, vim.inspect(names)))
    for _, name in ipairs(names) do
      if name == expected then
        return true
      end
    end
    return false
  end
end)

asserts.create("virtual_text"):register(function(self)
  return function(_, args)
    local expected = args[1]
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".") - 1
    local chunk = vim.api.nvim_buf_get_virtual_text(bufnr, line)[1]
    local actual = chunk[1]
    self:set_positive(("virtual_text should be %s, but actual: %s"):format(expected, actual))
    self:set_negative(("virtual_text should not be %s, but actual: %s"):format(expected, actual))
    return expected == actual
  end
end)

return M
