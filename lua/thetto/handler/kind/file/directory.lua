local filelib = require("thetto.lib.file")

local M = {}

function M.after(_) end

function M.action_cd(_, items)
  for _, item in ipairs(items) do
    vim.cmd("lcd " .. filelib.escape(item.path))
    M.after(item.path)
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tabedit")
    vim.cmd("lcd " .. filelib.escape(item.path))
    M.after(item.path)
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("vsplit")
    vim.cmd("lcd " .. filelib.escape(item.path))
    M.after(item.path)
  end
end

function M.action_enter(_, items)
  local item = items[1]
  if item == nil then
    return
  end
  require("thetto").start("file/in_dir", { opts = { cwd = item.path } })
end

M.action_open = M.action_cd
M.action_directory_open = M.action_open
M.action_directory_tab_open = M.action_tab_open
M.action_directory_enter = M.action_enter
M.action_list_children = M.action_enter

M.default_action = "cd"

return M
