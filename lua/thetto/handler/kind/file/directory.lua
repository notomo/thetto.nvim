local filelib = require("thetto.lib.file")

local M = {}

function M.after(_, _) end

function M.action_cd(items)
  for _, item in ipairs(items) do
    filelib.lcd(item.path)
    M.after(item.path)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    require("thetto.lib.buffer").open_scratch_tab()
    filelib.lcd(item.path)
    M.after(item.path)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    vim.cmd.vsplit()
    filelib.lcd(item.path)
    M.after(item.path)
  end
end

function M.action_enter(items)
  local item = items[1]
  if item == nil then
    return
  end
  return require("thetto").start("file/in_dir", { opts = { cwd = item.path } })
end

function M.action_preview(_, _, ctx)
  local item = ctx.ui:current_item()
  if item == nil then
    return
  end
  local is_preview = true
  local bufnr = M.after(item.path, is_preview)
  if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
    return nil, ctx.ui:open_preview(item, {
      raw_bufnr = bufnr,
    })
  end
end

function M.action_list_parents(items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fn.fnamemodify(item.path, ":h:h:h")
  return require("thetto").start("file/in_dir", { opts = { cwd = path } })
end

M.action_open = M.action_cd
M.action_directory_open = M.action_open
M.action_directory_tab_open = M.action_tab_open
M.action_directory_enter = M.action_enter
M.action_list_children = M.action_enter

M.default_action = "cd"

return M
