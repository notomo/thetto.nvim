local windowlib = require("thetto/lib/window")
local filelib = require("thetto/lib/file")
local highlights = require("thetto/lib/highlight")
local repository = require("thetto/core/repository")
local ItemList = require("thetto/view/item_list").ItemList
local Inputter = require("thetto/view/inputter").Inputter
local StatusLine = require("thetto/view/status_line").StatusLine
local vim = vim

local get_width = function()
  return math.floor(vim.o.columns * 0.6)
end

local get_column = function()
  return (vim.o.columns - get_width()) / 2
end

local M = {}

local WindowGroup = {}
WindowGroup.__index = WindowGroup
M.WindowGroup = WindowGroup

function WindowGroup.open(collector, active)
  local tbl = {_preview_hl_factory = highlights.new_factory("thetto-preview")}

  local self = setmetatable(tbl, WindowGroup)

  local source_name = collector.source.name
  local input_lines = collector.input_lines

  local height = math.floor(vim.o.lines * 0.5)
  local width = get_width()
  local row = (vim.o.lines - height - #input_lines) / 2
  local column = get_column()

  self.inputter = Inputter.new(collector, width, height, row, column)
  self.item_list = ItemList.new(source_name, collector.opts.display_limit, width, height, row, column)
  self.status_line = StatusLine.new(source_name, width, height, row, column)
  self._buffers = {input = self.inputter.bufnr, list = self.item_list.bufnr}

  self.list = self.item_list.window
  self.input = self.inputter.window
  self._windows = {
    self.list,
    self.item_list._sign_window, -- TODO
    self.input,
    self.status_line.window,
    self.inputter._filter_info_window, -- TODO
  }

  self:_set_left_padding()

  self:enter(active)
  -- NOTICE: set autocmd in the end not to fire it
  self.item_list:enable_on_moved(source_name)

  return self
end

function WindowGroup.is_current(self, name)
  local bufnr = self._buffers[name]
  return vim.api.nvim_get_current_buf() == bufnr
end

function WindowGroup.enter(self, to)
  windowlib.enter(self[to])
end

function WindowGroup.open_sidecar(self, item, open_target)
  if not self.item_list:is_valid() then
    return
  end
  if open_target.bufnr ~= nil and not vim.api.nvim_buf_is_valid(open_target.bufnr) then
    return
  end

  local list_config = vim.api.nvim_win_get_config(self.list)
  local height = list_config.height + self.inputter.height + 1
  local half_height = math.floor(height / 2)

  local top_row = 1
  local row = open_target.row
  if open_target.row ~= nil and open_target.row > half_height then
    top_row = open_target.row - half_height + 1
    row = half_height
  end

  local lines
  if open_target.bufnr ~= nil then
    lines = vim.api.nvim_buf_get_lines(open_target.bufnr, top_row - 1, top_row + height - 1, false)
  elseif open_target.path ~= nil then
    lines = filelib.read_lines(open_target.path, top_row, top_row + height)
  elseif open_target.lines ~= nil then
    lines = open_target.lines
  else
    lines = {}
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"

  local left_column = 2
  self:move_to(left_column)

  if not self:opened_sidecar() then
    local width = get_width()
    self.sidecar = vim.api.nvim_open_win(bufnr, false, {
      width = vim.o.columns - left_column - width - 3,
      height = height,
      relative = "editor",
      row = list_config.row,
      col = left_column + width + 1,
      focusable = false,
      external = false,
      style = "minimal",
    })
    vim.wo[self.sidecar].scrollbind = false
  else
    vim.api.nvim_win_set_buf(self.sidecar, bufnr)
  end

  local index
  if item then
    index = item.index
  end
  self._sidecar_index = index

  if open_target.execute ~= nil then
    local origin = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(self.sidecar)
    open_target.execute()
    vim.api.nvim_set_current_win(origin)
  end

  if row ~= nil then
    local highlighter = self._preview_hl_factory:create(bufnr)
    local range = open_target.range or {s = {column = 0}, e = {column = -1}}
    highlighter:add("ThettoPreview", row - 1, range.s.column, range.e.column)
    if vim.fn.getbufline(bufnr, row)[1] == "" then
      highlighter:set_virtual_text(row - 1, {{"(empty)", "ThettoPreview"}})
    end
  end
end

function WindowGroup.opened_sidecar(self)
  return self.sidecar ~= nil and vim.api.nvim_win_is_valid(self.sidecar)
end

function WindowGroup.exists_same_sidecar(self, item)
  if not self:opened_sidecar() then
    return false
  end
  return item ~= nil and item.index == self._sidecar_index
end

function WindowGroup.close_sidecar(self)
  if self.sidecar ~= nil then
    windowlib.close(self.sidecar)
    self.sidecar = nil
    self._sidecar_index = nil
    self:reset_position()
  end
end

function WindowGroup.has(self, window_id)
  for _, id in ipairs(self._windows) do
    if window_id == id then
      return true
    end
  end
  return false
end

function WindowGroup.close(self)
  -- TODO: remove self._windows
  for _, id in pairs(self._windows) do
    windowlib.close(id)
  end
  self:close_sidecar()
  vim.cmd("autocmd! " .. "theto_closed_" .. self._buffers.list)
end

function WindowGroup.move_to(self, left_column)
  self.item_list:move_to(left_column)
  self.inputter:move_to(left_column)
  self.status_line:move_to(left_column)
  self:_set_left_padding()
end

function WindowGroup.reset_position(self)
  if not self.item_list:is_valid() then
    return
  end
  self:move_to(get_column())
end

function WindowGroup.redraw(self, draw_ctx)
  if not self.item_list:is_valid() then
    return
  end

  local items = draw_ctx.items
  local source = draw_ctx.source
  local input_lines = draw_ctx.input_lines

  self.item_list:redraw(items, source, input_lines, draw_ctx.filters, draw_ctx.opts)
  self.status_line:redraw(source, items, draw_ctx.sorters, draw_ctx.finished, draw_ctx.result_count)
  self.inputter:redraw(input_lines, draw_ctx.filters)
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function WindowGroup._set_left_padding(self)
  self.inputter:set_left_padding()
  self.status_line:set_left_padding()
end

M._on_enter = function(key, to)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:enter(to)
end

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
