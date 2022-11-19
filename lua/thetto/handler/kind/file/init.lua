local filelib = require("thetto.lib.file")

local M = {}
M.__index = M

local adjust_cursor = function(item)
  if item.pattern ~= nil then
    vim.fn.search(item.pattern)
    vim.fn.setreg("/", item.pattern)
    vim.opt.hlsearch = true
    vim.cmd.let({ args = { "v:searchforward", "=", "1" } })
    return
  end

  if item.row == nil then
    return
  end
  local count = vim.api.nvim_buf_line_count(0)
  local row = item.row
  if item.row > count then
    row = count
  end
  local range = item.range or { s = { column = 0 } }
  vim.api.nvim_win_set_cursor(0, { row, range.s.column })
end

local get_bufnr = function(item)
  local pattern = ("^%s$"):format(item.path)
  return vim.fn.bufnr(pattern)
end

function M.escape(path)
  return ([[`='%s'`]]):format(path:gsub("'", "''"))
end

function M.action_open(items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.edit(filelib.escape(item.path))
    end
    adjust_cursor(item)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      require("thetto.lib.buffer").open_scratch_tab()
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.tabedit(filelib.escape(item.path))
    end
    adjust_cursor(item)
  end
end

function M.action_tab_drop(items)
  for _, item in ipairs(items) do
    vim.cmd.drop({ mods = { tab = 0 }, args = { filelib.escape(item.path) } })
    adjust_cursor(item)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.cmd.vsplit()
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.vsplit(filelib.escape(item.path))
    end
    adjust_cursor(item)
  end
end

function M.action_preview(items, _, ctx)
  local item = items[1]
  if item == nil then
    return
  end
  local bufnr = get_bufnr(item)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return nil, ctx.ui:open_preview(item, { bufnr = bufnr, row = item.row, range = item.range })
  else
    return nil, ctx.ui:open_preview(item, { path = item.path, row = item.row, range = item.range })
  end
end

function M.action_load_buffer(items)
  for _, item in ipairs(items) do
    local bufnr = vim.fn.bufadd(item.path)
    vim.fn.bufload(bufnr)
  end
end

function M.action_delete_buffer(items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end
end

local to_dirs = function(items)
  local dirs = {}
  for _, item in ipairs(items) do
    local cloned = vim.deepcopy(item)
    cloned.path = vim.fn.fnamemodify(item.path, ":h")
    table.insert(dirs, cloned)
  end
  return dirs
end

function M.action_directory_open(items, _, ctx)
  return require("thetto.util.action").call("file/directory", "open", to_dirs(items), ctx)
end

function M.action_directory_tab_open(items, _, ctx)
  return require("thetto.util.action").call("file/directory", "tab_open", to_dirs(items), ctx)
end

function M.action_directory_enter(items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fn.fnamemodify(item.path, ":h")
  return require("thetto").start("file/in_dir", { opts = { cwd = path } })
end

function M.action_list_parents(items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fn.fnamemodify(item.path, ":h:h")
  return require("thetto").start("file/in_dir", { opts = { cwd = path } })
end

M.action_list_siblings = M.action_directory_enter

M.default_action = "open"

return M
