local M = {}

local root, find_err = require("thetto/lib/path").find_root("thetto/*.lua")
if find_err ~= nil then
  error(find_err)
end
M.root = root

M.test_data_path = "spec/test_data/"
M.test_data_dir = M.root .. "/" .. M.test_data_path

-- HACK
vim.cmd("autocmd SwapExists * lua vim.v.swapchoice = 'd'")

function M.command(cmd)
  local _, err = pcall(vim.cmd, cmd)
  if err and err ~= "" then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local msg = ("on %s: failed excmd `%s`\n%s"):format(pos, cmd, err)
    error(msg)
  end
end

function M.before_each()
  M.command("filetype on")
  M.command("syntax enable")
  M.new_directory("")
  vim.api.nvim_set_current_dir(M.test_data_dir)
end

function M.after_each()
  -- avoid segmentation fault??
  M.command("tabedit")
  M.command("tabprevious")
  M.command("quit!")

  M.command("tabedit")
  M.command("tabonly!")
  M.command("silent! %bwipeout!")
  M.command("filetype off")
  M.command("syntax off")
  print(" \n")

  require("thetto/lib/module").cleanup()
  M.delete("")
end

function M.buffer_log()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

function M.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

function M.sync_input(texts)
  local text = texts[1]
  local finished = false
  require("thetto/view/ui")._changed_after = function(input_lines)
    for _, line in ipairs(input_lines) do
      if vim.endswith(line, text) then
        finished = true
      end
    end
  end
  vim.api.nvim_put({text}, "c", true, true)
  local ok = vim.wait(1000, function()
    return finished
  end, 10)
  if not ok then
    assert(false, "wait timeout")
  end
end

function M.sync_open(...)
  local _range = nil
  local collector = require("thetto/entrypoint/command").start_by_excmd(0, _range, {...})
  if collector == nil then
    return
  end
  local ok = collector:wait(1000)
  if not ok then
    assert(false, "job wait timeout")
  end

  local finished = false
  require("thetto/view/ui")._changed_after = function()
    finished = collector:finished()
  end
  ok = vim.wait(1000, function()
    return finished
  end, 10)
  if not ok then
    assert(false, "wait timeout")
  end

  return collector
end

function M.sync_execute(...)
  local _range = nil
  local job = require("thetto/entrypoint/command").execute(0, _range, {...})
  if job == nil then
    return
  end
  local ok = job:wait(1000)
  if not ok then
    assert(false, "job wait timeout")
  end
end

function M.wait_ui(f)
  local finished = false
  require("thetto/view/ui")._changed_after = function(_)
    finished = true
  end

  f()

  local ok = vim.wait(1000, function()
    return finished
  end, 10)
  if not ok then
    assert(false, "wait ui timeout")
  end
end

function M.search(pattern)
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

function M.new_file(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({...}) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.new_directory(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

function M.delete(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

function M.cd(path)
  vim.api.nvim_set_current_dir(M.test_data_dir .. path)
end

function M.path(path)
  return M.test_data_dir .. (path or "")
end

function M.window_count()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end

function M.sub_windows()
  local windows = {}
  for bufnr, id in require("thetto/lib/buffer").in_tabpage(0) do
    local config = vim.api.nvim_win_get_config(id)
    if config.relative ~= "" and vim.bo[bufnr].filetype == "" then
      table.insert(windows, id)
    end
  end
  return windows
end

local asserts = require("vusted.assert").asserts

asserts.create("window"):register_eq(function()
  return vim.api.nvim_get_current_win()
end)

asserts.create("window_count"):register_eq(function()
  return M.window_count()
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

asserts.create("dir_name"):register_eq(function()
  return vim.fn.fnamemodify(vim.fn.bufname("%"), ":h:t")
end)

asserts.create("filetype"):register_eq(function()
  return vim.bo.filetype
end)

asserts.create("current_dir"):register_eq(function()
  return vim.fn.getcwd():gsub(M.test_data_dir .. "?", "")
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

return M
