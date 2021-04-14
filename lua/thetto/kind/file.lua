local M = {}
M.__index = M

local adjust_cursor = function(item)
  if item.row == nil then
    return
  end
  local count = vim.api.nvim_buf_line_count(0)
  local row = item.row
  if item.row > count then
    row = count
  end
  local range = item.range or {s = {column = 0}}
  vim.api.nvim_win_set_cursor(0, {row, range.s.column})
end

local get_bufnr = function(item)
  local pattern = ("^%s$"):format(item.path)
  return vim.fn.bufnr(pattern)
end

function M.action_open(_, items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.cmd("buffer " .. bufnr)
    else
      vim.cmd("edit " .. item.path)
    end
    adjust_cursor(item)
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.cmd("tabedit")
      vim.cmd("buffer " .. bufnr)
    else
      vim.cmd("tabedit " .. item.path)
    end
    adjust_cursor(item)
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.cmd("vsplit")
      vim.cmd("buffer " .. bufnr)
    else
      vim.cmd("vsplit" .. item.path)
    end
    adjust_cursor(item)
  end
end

function M.action_preview(_, items, ctx)
  local item = items[1]
  if item == nil then
    return
  end
  local bufnr = get_bufnr(item)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    ctx.ui:open_preview(item, {bufnr = bufnr, row = item.row, range = item.range})
  else
    ctx.ui:open_preview(item, {path = item.path, row = item.row, range = item.range})
  end
end

local directory_kind = require("thetto/kind/directory")

local to_dirs = function(items)
  local dirs = {}
  for _, item in ipairs(items) do
    item.path = vim.fn.fnamemodify(item.path, ":h")
    item.value = item.path
    table.insert(dirs, item)
  end
  return dirs
end

function M.action_directory_open(self, items)
  directory_kind.action_open(self, to_dirs(items))
end

function M.action_directory_tab_open(self, items)
  directory_kind.action_tab_open(self, to_dirs(items))
end

function M.action_directory_enter(_, items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fn.fnamemodify(item.path, ":h")
  vim.cmd("Thetto file/in_dir --cwd=" .. path)
end

M.default_action = "open"

return M
