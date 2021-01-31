local ItemList = require("thetto/view/item_list").ItemList
local Inputter = require("thetto/view/inputter").Inputter
local StatusLine = require("thetto/view/status_line").StatusLine
local Sidecar = require("thetto/view/sidecar").Sidecar
local bufferlib = require("thetto/lib/buffer")
local repository = require("thetto/core/repository")
local listlib = require("thetto/lib/list")
local vim = vim

local M = {}

local UI = {}
UI.__index = UI
M.UI = UI

function UI.new(collector)
  local tbl = {_collector = collector, _row = 1, _input_cursor = nil}

  if collector.opts.insert then
    tbl._active = "input"
    tbl._mode = "i"
  else
    tbl._active = "list"
    tbl._mode = "n"
  end

  return setmetatable(tbl, UI)
end

function UI.open(self, on_move)
  vim.validate({on_move = {on_move, "function"}})

  for bufnr in bufferlib.in_tabpage(0) do
    local ctx, _ = repository.get_from_path(bufnr)
    if ctx ~= nil then
      ctx.ui:close()
    end
  end

  self._origin_window = vim.api.nvim_get_current_win()

  local source_name = self._collector.source.name
  local input_lines = self._collector.input_lines

  local height = math.floor(vim.o.lines * 0.5)
  local width = self:_width()
  local row = (vim.o.lines - height - #input_lines) / 2
  local column = self:_column()

  self._inputter = Inputter.new(self._collector, width, height, row, column)
  self._item_list = ItemList.new(source_name, self._collector.opts.display_limit, width, height, row, column)
  self._status_line = StatusLine.new(source_name, width, height, row, column)
  self._sidecar = Sidecar.new()

  if self._active == "input" then
    self._inputter:enter()
  else
    self._item_list:enter()
  end

  -- NOTICE: set autocmd in the end not to fire it
  self._item_list:enable_on_moved(source_name)

  self._collector:attach_ui(self)
  self._on_move = on_move

  if self._mode == "n" then
    vim.cmd("stopinsert")
  else
    vim.cmd("startinsert")
  end
end

function UI.scroll(self, offset)
  if offset ~= 0 then
    self:update_offset(offset)
    self._item_list:set_row(self._row)
  end
end

function UI.resume(self)
  self:close()
  self:open(self._on_move)

  if self._input_cursor ~= nil then
    self._inputter:set_cursor(self._input_cursor)
    self._input_cursor = nil
  end

  return self:redraw(self._collector.input_lines, self._row)
end

function UI.redraw(self, input_lines, row)
  if self._item_list:is_valid() then
    local draw_ctx = {
      filters = self._collector.filters:values(),
      sorters = self._collector.sorters:values(),
      source = self._collector.source,
      result_count = self._collector.result:count(),
      finished = self._collector:finished(),
      opts = self._collector.opts,
      items = self._collector.items:values(),
      input_lines = input_lines,
    }
    local items = draw_ctx.items
    local source = draw_ctx.source
    self._item_list:redraw(items, source, input_lines, draw_ctx.filters, draw_ctx.opts)
    self._status_line:redraw(source, items, draw_ctx.sorters, draw_ctx.finished, draw_ctx.result_count)
    self._inputter:redraw(input_lines, draw_ctx.filters)
  end

  if row ~= nil then
    self._item_list:set_row(row)
  end

  local err = self:on_move()
  if err ~= nil then
    return err
  end

  M._changed_after(input_lines)
end

function UI.on_move(self)
  local item_group = self:current_item_groups()[1]
  return self._on_move(item_group)
end

function UI.update_offset(self, offset)
  local row = self._row + offset
  local line_count = self._collector.items:length()
  if self._collector.opts.display_limit < line_count then
    line_count = self._collector.opts.display_limit
  end
  if line_count < row then
    row = line_count
  elseif row < 1 then
    row = 1
  end
  self._row = row
end

function UI.close(self)
  if self._item_list == nil then
    return
  end

  local current_window = vim.api.nvim_get_current_win()

  if self._item_list:is_valid() then
    self._row = self._item_list:cursor()[1]
    local active = "input"
    if self._item_list:is_active() then
      active = "list"
    end
    self._active = active
    self._mode = vim.api.nvim_get_mode().mode
  end

  if self._inputter:is_valid() then
    self._input_cursor = self._inputter:cursor()
  end

  self._item_list:close()
  self._inputter:close()
  self._status_line:close()
  self:close_preview()

  if vim.api.nvim_win_is_valid(current_window) then
    vim.api.nvim_set_current_win(current_window)
  elseif vim.api.nvim_win_is_valid(self._origin_window) then
    vim.api.nvim_set_current_win(self._origin_window)
  end

  self._collector:discard()
end

function UI.into_list(self)
  self._item_list:enter()
end

function UI.into_inputter(self)
  self._inputter:enter()
end

function UI.current_position_filter(self)
  local cursor = self._inputter:cursor()
  return self._collector.filters[cursor[1]]
end

function UI.start_insert(self, behavior)
  self._inputter:start_insert(behavior)
end

function UI.current_item_groups(self, action_name, range)
  local items = self:_selected_items(action_name, range)
  local item_groups = listlib.group_by(items, function(item)
    return item.kind_name or self._collector.source.kind_name
  end)
  if #item_groups == 0 then
    table.insert(item_groups, {"base", {}})
  end
  return item_groups
end

function UI._selected_items(self, action_name, range)
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self._collector.selected) then
    local selected = vim.tbl_values(self._collector.selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  if range ~= nil and self._item_list:is_active() then
    local items = {}
    for i = range.first, range.last, 1 do
      table.insert(items, self._collector.items[i])
    end
    return items
  end

  local index
  if self._inputter:is_active() then
    index = 1
  elseif self._item_list:is_active() then
    index = vim.fn.line(".")
  else
    index = self._row
  end
  return {self._collector.items[index]}
end

function UI.open_preview(self, item, open_target)
  if not self._item_list:is_valid() then
    return
  end

  local pos = self._item_list:position()
  local height = pos.height + self._inputter.height + 1
  local left_column = 2
  local width = self:_width()
  local row = pos.row

  self:_move_to(left_column)
  self._sidecar:open(item, open_target, width, height, row, left_column)
end

function UI.exists_same_preview(self, items)
  return self._sidecar:exists_same(items[1])
end

function UI.close_preview(self)
  self._sidecar:close()
  if not self._item_list:is_valid() then
    return
  end
  self:_move_to(self:_column())
end

function UI.redraw_selections(self, items)
  return self._item_list:redraw_selections(items)
end

function UI.has_window(self, id)
  return self._item_list:has(id) or self._inputter:has(id) or self._status_line:has(id)
end

function UI._move_to(self, left_column)
  self._item_list:move_to(left_column)
  self._inputter:move_to(left_column)
  self._status_line:move_to(left_column)
end

function UI._width()
  return math.floor(vim.o.columns * 0.6)
end

function UI._column(self)
  return (vim.o.columns - self:_width()) / 2
end

-- for testing
M._changed_after = function(_)
end

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
