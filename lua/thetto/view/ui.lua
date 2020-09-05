local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local repository = require("thetto/core/repository")
local window_groups = require("thetto/view/window_group")

local M = {}

local UI = {}
UI.__index = UI

function UI.open(self)
  local source = self.collector.source
  local opts = self.collector.opts

  for bufnr in bufferlib.in_tabpage(0) do
    local ctx, _ = repository.get_from_path(bufnr)
    if ctx ~= nil then
      ctx.ui:close()
    end
  end

  self.origin_window = vim.api.nvim_get_current_win()
  self.windows = window_groups.open(self.notifier, source.name, self.collector.input_lines, opts.display_limit)

  self:enter(self.active)

  if self.mode == "n" then
    vim.api.nvim_command("stopinsert")
  else
    vim.api.nvim_command("startinsert")
  end
end

function UI.resume(self)
  self:close()
  self:open()

  if self.input_cursor ~= nil then
    vim.api.nvim_win_set_cursor(self.windows.input, self.input_cursor)
    self.input_cursor = nil
  end

  return self.notifier:send("update_items", self.collector.input_lines, self.row)
end

function UI.redraw(self, input_lines)
  self.windows:redraw(self.collector, input_lines)
end

function UI.update_offset(self, offset)
  local row = self.row + offset
  local line_count = #self.collector.items
  if self.collector.opts.display_limit < line_count then
    line_count = self.collector.opts.display_limit
  end
  if line_count < row then
    row = line_count
  elseif row < 1 then
    row = 1
  end
  self.row = row
end

function UI.close(self)
  if self.windows == nil then
    return
  end

  local current_window = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(self.windows.list) then
    self.row = vim.api.nvim_win_get_cursor(self.windows.list)[1]
    local active = "input"
    if vim.api.nvim_get_current_win() == self.windows.list then
      active = "list"
    end
    self.active = active
    self.mode = vim.api.nvim_get_mode().mode
  end

  if vim.api.nvim_win_is_valid(self.windows.input) then
    self.input_cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  end

  self.windows:close()

  if vim.api.nvim_win_is_valid(current_window) then
    vim.api.nvim_set_current_win(current_window)
  elseif vim.api.nvim_win_is_valid(self.origin_window) then
    vim.api.nvim_set_current_win(self.origin_window)
  end

  self.notifier:send("finish")
end

function UI.enter(self, to)
  windowlib.enter(self.windows[to])
end

function UI.current_position_filter(self)
  local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  return self.collector.filters[cursor[1]]
end

function UI.current_position_sorter(self)
  local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  return self.collector.sorters[cursor[1]]
end

function UI.start_insert(self, behavior)
  vim.api.nvim_command("startinsert")
  if behavior == "a" then
    local max_col = vim.fn.col("$")
    local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
    if cursor[2] ~= max_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(self.windows.input, cursor)
    end
  end
end

function UI.selected_items(self, action_name, range)
  range = range or {}

  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self.collector.selected) then
    local selected = vim.tbl_values(self.collector.selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  if range.given and self.windows:is_current("list") then
    local items = {}
    for i = range.first, range.last, 1 do
      table.insert(items, self.collector.items[i])
    end
    return items
  end

  local index
  if self.windows:is_current("input") then
    index = 1
  elseif self.windows:is_current("list") then
    index = vim.fn.line(".")
  else
    index = self.row
  end
  return {self.collector.items[index]}
end

function UI.open_preview(self, open_target)
  self.windows:open_sidecar(self.collector, open_target)
end

function UI.opened_preview(self)
  return self.windows:opened_sidecar()
end

function UI.close_preview(self)
  self.windows:close_sidecar()
end

M.new = function(collector, notifier)
  local tbl = {
    collector = collector,
    notifier = notifier,
    row = 1,
    windows = nil,
    input_cursor = nil,
  }

  if collector.opts.insert then
    tbl.active = "input"
    tbl.mode = "i"
  else
    tbl.active = "list"
    tbl.mode = "n"
  end

  local self = setmetatable(tbl, UI)

  self.notifier:on("update_items", function(input_lines, row)
    local err = self:redraw(input_lines)
    if err ~= nil then
      return err
    end
    if row ~= nil then
      vim.api.nvim_win_set_cursor(self.windows.list, {row, 0})
    end
    err = self.notifier:send("execute")
    if err ~= nil then
      return err
    end
    M._changed_after(input_lines)
  end)

  self.notifier:on("update_selected", function()
    self.windows:redraw_selections(self.collector)
  end)

  self.notifier:on("close", function()
    self:close()
  end)

  return self
end

M._on_close = function(key, id)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  if not ui.windows:has(id) then
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
  ui.notifier:send("execute")
end

-- for testing
M._changed_after = function(_)
end

return M
