local filelib = require("thetto.lib.file")

local M = {}

local after = function(path, bufnr)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "ThettoDirectoryOpened",
    modeline = false,
    data = {
      path = path,
      bufnr = bufnr,
    },
  })
end

function M.action_cd(items)
  for _, item in ipairs(items) do
    filelib.lcd(item.path)
    after(item.path)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    require("thetto.lib.buffer").open_scratch_tab()
    filelib.lcd(item.path)
    after(item.path)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    vim.cmd.vsplit()
    filelib.lcd(item.path)
    after(item.path)
  end
end

function M.action_enter(items)
  local item = items[1]
  if item == nil then
    return
  end
  local source = require("thetto.util.source").by_name("file/in_dir", { cwd = item.path })
  return require("thetto").start(source)
end

function M.get_preview(item)
  local bufnr = vim.api.nvim_create_buf(false, true)
  after(item.path, bufnr)
  if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
    return nil, {
      raw_bufnr = bufnr,
    }
  end
end

function M.action_list_parents(items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fs.dirname(item.path)
  local source = require("thetto.util.source").by_name("file/in_dir", { cwd = path })
  return require("thetto").start(source)
end

function M.action_delete(items)
  for _, item in ipairs(items) do
    vim.fn.delete(item.path, "rf")
  end
end

M.action_open = M.action_cd
M.action_directory_open = M.action_open
M.action_directory_tab_open = M.action_tab_open
M.action_directory_enter = M.action_enter
M.action_list_children = M.action_enter

M.default_action = "cd"

return M
