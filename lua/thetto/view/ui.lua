local bufferlib = require("thetto/lib/buffer")
local repository = require("thetto/core/repository")
local WindowGroup = require("thetto/view/window_group").WindowGroup
local listlib = require("thetto/lib/list")
local vim = vim

local M = {}

local UI = {}
UI.__index = UI
M.UI = UI

function UI.new(collector)
  local tbl = {_collector = collector, _row = 1, _windows = nil, _input_cursor = nil}

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
  self._windows = WindowGroup.open(self._collector, self._active)
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
    self._windows.item_list:set_row(self._row)
  end
end

function UI.resume(self)
  self:close()
  self:open(self._on_move)

  if self._input_cursor ~= nil then
    vim.api.nvim_win_set_cursor(self._windows.input, self._input_cursor)
    self._input_cursor = nil
  end

  return self:redraw(self._collector.input_lines, self._row)
end

function UI.redraw(self, input_lines, row)
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
  self._windows:redraw(draw_ctx)
  if row ~= nil then
    vim.api.nvim_win_set_cursor(self._windows.list, {row, 0})
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
  if self._windows == nil then
    return
  end

  local current_window = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(self._windows.list) then
    self._row = vim.api.nvim_win_get_cursor(self._windows.list)[1]
    local active = "input"
    if vim.api.nvim_get_current_win() == self._windows.list then
      active = "list"
    end
    self._active = active
    self._mode = vim.api.nvim_get_mode().mode
  end

  if vim.api.nvim_win_is_valid(self._windows.input) then
    self._input_cursor = vim.api.nvim_win_get_cursor(self._windows.input)
  end

  self._windows:close()

  if vim.api.nvim_win_is_valid(current_window) then
    vim.api.nvim_set_current_win(current_window)
  elseif vim.api.nvim_win_is_valid(self._origin_window) then
    vim.api.nvim_set_current_win(self._origin_window)
  end

  self._collector:discard()
end

function UI.enter(self, to)
  self._windows:enter(to)
end

function UI.current_position_filter(self)
  local cursor = vim.api.nvim_win_get_cursor(self._windows.input)
  return self._collector.filters[cursor[1]]
end

function UI.current_position_sorter(self)
  local cursor = vim.api.nvim_win_get_cursor(self._windows.input)
  return self._collector.sorters[cursor[1]]
end

function UI.start_insert(self, behavior)
  vim.cmd("startinsert")
  if behavior == "a" then
    local max_col = vim.fn.col("$")
    local cursor = vim.api.nvim_win_get_cursor(self._windows.input)
    if cursor[2] ~= max_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(self._windows.input, cursor)
    end
  end
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

  if range ~= nil and self._windows:is_current("list") then
    local items = {}
    for i = range.first, range.last, 1 do
      table.insert(items, self._collector.items[i])
    end
    return items
  end

  local index
  if self._windows:is_current("input") then
    index = 1
  elseif self._windows:is_current("list") then
    index = vim.fn.line(".")
  else
    index = self._row
  end
  return {self._collector.items[index]}
end

function UI.open_preview(self, item, open_target)
  self._windows:open_sidecar(item, open_target)
end

function UI.exists_same_preview(self, items)
  return self._windows:exists_same_sidecar(items[1])
end

function UI.close_preview(self)
  self._windows:close_sidecar()
end

function UI.has_window(self, id)
  return self._windows:has(id)
end

function UI.redraw_selections(self, items)
  return self._windows.item_list:redraw_selections(items)
end

-- for testing
M._changed_after = function(_)
end

return M
