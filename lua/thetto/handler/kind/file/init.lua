local M = {}

M.opts = {}

local adjust_cursor = function(item)
  if item.pattern ~= nil then
    vim.fn.search(item.pattern)
    vim.fn.setreg("/", item.pattern)
    vim.opt.hlsearch = true
    vim.v.searchforward = 1
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

  vim.api.nvim_win_set_cursor(0, { row, item.column or 0 })
end

function M.action_open(items)
  for _, item in ipairs(items) do
    local bufnr = require("thetto.vendor.misclib.buffer").find(item.path)
    if bufnr then
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.edit({ args = { item.path }, magic = { file = false } })
    end
    adjust_cursor(item)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    require("thetto.lib.buffer").open_scratch_tab()
    local bufnr = require("thetto.vendor.misclib.buffer").find(item.path)
    if bufnr then
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.edit({ args = { item.path }, magic = { file = false } })
    end
    adjust_cursor(item)
  end
end

function M.action_tab_drop(items)
  for _, item in ipairs(items) do
    local tab = vim.fn.tabpagenr()
    vim.cmd.drop({ mods = { tab = tab }, args = { item.path }, magic = { file = false } })
    adjust_cursor(item)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    local bufnr = require("thetto.vendor.misclib.buffer").find(item.path)
    if bufnr then
      vim.cmd.vsplit()
      vim.cmd.buffer(bufnr)
    else
      vim.cmd.vnew()
      vim.bo.buftype = "nofile"
      vim.bo.bufhidden = "wipe"
      vim.cmd.edit({ args = { item.path }, magic = { file = false } })
    end
    adjust_cursor(item)
  end
end

M.opts.preview = {
  ignore_patterns = {},
}
function M.get_preview(item, action_ctx)
  if require("thetto.lib.regex").match_any(item.path, action_ctx.opts.ignore_patterns or {}) then
    return nil, { lines = { "IGNORED" } }
  end
  if vim.fn.isdirectory(item.path) == 1 then
    return require("thetto.util.action").preview("file/directory", item, action_ctx)
  end
  local bufnr = require("thetto.vendor.misclib.buffer").find(item.path)
  if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
    return nil,
      {
        bufnr = bufnr,
        row = item.row,
        end_row = item.end_row,
        column = item.column,
        end_column = item.end_column,
        title = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr)),
      }
  end
  return nil,
    {
      path = item.path,
      row = item.row,
      end_row = item.end_row,
      column = item.column,
      end_column = item.end_column,
      title = vim.fs.basename(item.path),
    }
end

function M.action_load_buffer(items)
  for _, item in ipairs(items) do
    local bufnr = vim.fn.bufadd(item.path)
    vim.fn.bufload(bufnr)
  end
end

function M.action_delete_buffer(items)
  for _, item in ipairs(items) do
    local bufnr = require("thetto.vendor.misclib.buffer").find(item.path)
    if bufnr then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end
end

function M.action_delete(items)
  for _, item in ipairs(items) do
    vim.fn.delete(item.path, "rf")
  end
end

local to_dirs = function(items)
  local dirs = {}
  for _, item in ipairs(items) do
    local cloned = vim.deepcopy(item)
    cloned.path = vim.fs.dirname(item.path)
    table.insert(dirs, cloned)
  end
  return dirs
end

function M.action_directory_open(items)
  return require("thetto.util.action").call("file/directory", "open", to_dirs(items))
end

function M.action_directory_tab_open(items)
  return require("thetto.util.action").call("file/directory", "tab_open", to_dirs(items))
end

function M.action_directory_enter(items)
  local item = items[1]
  if item == nil then
    return
  end
  local path = vim.fs.dirname(item.path)
  local source = require("thetto.util.source").by_name("file/in_dir", { cwd = path })
  return require("thetto").start(source)
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

M.action_list_siblings = M.action_directory_enter

M.default_action = "open"

return M
