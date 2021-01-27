local windowlib = require("thetto/lib/window")
local cursorlib = require("thetto/lib/cursor")
local bufferlib = require("thetto/lib/buffer")
local filelib = require("thetto/lib/file")
local highlights = require("thetto/lib/highlight")
local repository = require("thetto/core/repository")
local ItemList = require("thetto/view/item_list").ItemList
local Inputter = require("thetto/view/inputter").Inputter
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
  local tbl = {
    _preview_hl_factory = highlights.new_factory("thetto-preview"),
    _info_hl_factory = highlights.new_factory("thetto-info-text"),
  }

  local self = setmetatable(tbl, WindowGroup)

  local source_name = collector.source.name
  local input_lines = collector.input_lines

  local height = math.floor(vim.o.lines * 0.5)
  local width = get_width()
  local row = (vim.o.lines - height - #input_lines) / 2
  local column = get_column()

  local inputter = Inputter.new(collector, width, height, row, column)
  local item_list = ItemList.new(source_name, collector.opts.display_limit, width, height, row, column)

  local info_bufnr = bufferlib.scratch(function(bufnr)
    vim.bo[bufnr].modifiable = false
  end)
  self._buffers = {input = inputter.bufnr, list = item_list.bufnr, info = info_bufnr}
  self.item_list = item_list
  self.inputter = inputter

  local info_window = vim.api.nvim_open_win(self._buffers.info, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[info_window].winhighlight = "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo"
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'input')"):format(self._buffers.info, source_name)
  vim.cmd(on_info_enter)

  local group_name = self:_close_group_name()
  vim.cmd(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/window_group')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"):format(group_name, source_name)
  vim.cmd(on_win_closed)
  vim.cmd("augroup END")

  self.list = item_list.window
  self._sign = item_list._sign_window -- TODO
  self.input = inputter.window
  self._info = info_window
  self._filter_info = inputter._filter_info_window -- TODO
  self._windows = {self.list, self._sign, self.input, self._info, self._filter_info}

  self:_set_left_padding()

  self:enter(active)

  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/window_group')._on_moved('%s')"):format(self._buffers.list, source_name)
  vim.cmd(on_moved)

  local on_moved_i = ("autocmd CursorMovedI <buffer=%s> stopinsert"):format(self._buffers.list)
  vim.cmd(on_moved_i)

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
  if not vim.api.nvim_win_is_valid(self.list) then
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
  for _, id in pairs(self._windows) do
    windowlib.close(id)
  end
  self:close_sidecar()
  vim.cmd("autocmd! " .. self:_close_group_name())
end

function WindowGroup.move_to(self, left_column)
  self.item_list:move_to(left_column)
  self.inputter:move_to(left_column)
  local info_config = vim.api.nvim_win_get_config(self._info)
  vim.api.nvim_win_set_config(self._info, {
    relative = "editor",
    col = left_column,
    row = info_config.row,
  })
  self:_set_left_padding()
end

function WindowGroup.reset_position(self)
  if not vim.api.nvim_win_is_valid(self.list) then
    return
  end
  self:move_to(get_column())
end

function WindowGroup.set_row(self, row)
  cursorlib.set_row(row, self.list, self._buffers.list)
end

function WindowGroup.redraw(self, draw_ctx)
  if not vim.api.nvim_buf_is_valid(self._buffers.list) then
    return
  end

  local items = draw_ctx.items
  local source = draw_ctx.source
  local input_lines = draw_ctx.input_lines

  self.item_list:redraw(items, source, input_lines, draw_ctx.filters, draw_ctx.opts)
  self:_redraw_info(source, items, draw_ctx.sorters, draw_ctx.finished, draw_ctx.result_count)
  self.inputter:redraw(input_lines, draw_ctx.filters)
end

function WindowGroup._redraw_info(self, source, items, sorters, finished, result_count)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(sorters) do
    table.insert(sorter_names, sorter.name)
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local status = ""
  if not finished then
    status = "running"
  end

  local text = ("%s%s  [ %s / %s ]"):format(source.name, sorter_info, #items, result_count)
  local highlighter = self._info_hl_factory:reset(self._buffers.info)
  highlighter:set_virtual_text(0, {{text, "ThettoInfo"}, {"  " .. status, "Comment"}})
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function WindowGroup._set_left_padding(self)
  self.inputter:set_left_padding()
  vim.wo[self._info].signcolumn = "yes:1"
end

function WindowGroup._close_group_name(self)
  return "theto_closed_" .. self._buffers.list
end

M._on_close = function(key, id)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  if not ui:has_window(id) then
    return
  end

  ui:close()
end

M._on_enter = function(key, to)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:enter(to)
end

M._on_moved = function(key)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:on_move()
end

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
