local Context = require("thetto.core.context")
local ItemList = require("thetto.view.item_list")
local Inputter = require("thetto.view.inputter")
local StatusLine = require("thetto.view.status_line")
local Sidecar = require("thetto.view.sidecar")
local State = require("thetto.view.state")
local bufferlib = require("thetto.lib.buffer")
local vim = vim

local _item_list_ns = vim.api.nvim_create_namespace(ItemList.hl_ns_name)
local _inputter_ns = vim.api.nvim_create_namespace(Inputter.hl_ns_name)

local UI = {}
UI.__index = UI

function UI.new(collector, insert)
  vim.validate({
    collector = { collector, "table" },
    insert = { insert, "boolean" },
  })
  local tbl = {
    _collector = collector,
    _state = State.new(insert),
    _debounce_ms_on_move = 70,
    _initialized_preview = false,
  }
  return setmetatable(tbl, UI)
end

function UI.open(self, immediately, on_move, needs_preview)
  vim.validate({ on_move = { on_move, "function", true } })

  for bufnr in bufferlib.in_tabpage(0) do
    local ctx = Context.get_from_path(bufnr)
    if ctx then
      ctx.ui:close(true)
    end
  end

  local source_name = self._collector.source.name
  local input_lines = self._collector.input_lines
  local filters = self._collector.filters

  local height = self:_height()
  local width = self:_width()
  local row = self:_row(input_lines)
  local column = self:_column()

  self._inputter = Inputter.new(source_name, filters, input_lines, width, height, row, column)
  self._collector:subscribe_input(immediately, self._inputter:observable())

  self._item_list = ItemList.new(source_name, width, height, row, column)
  self._status_line = StatusLine.new(source_name, width, height, row, column)
  self._sidecar = Sidecar.new()

  self._state = self._state:resume(self._item_list, self._inputter)
  self._collector:attach_ui(self)
  self._on_move = on_move or function() end
  self._debounced_on_move = require("thetto.lib.wrap").debounce(self._debounce_ms_on_move, self._on_move)

  -- NOTICE: set autocmd in the end not to fire it
  self._item_list:enable_on_moved(source_name)

  vim.api.nvim_set_decoration_provider(_item_list_ns, {})
  vim.api.nvim_set_decoration_provider(_item_list_ns, { on_win = UI._highlight_item_list_win })
  vim.api.nvim_set_decoration_provider(_inputter_ns, {})
  vim.api.nvim_set_decoration_provider(_inputter_ns, { on_win = UI._highlight_inputter_win })

  if needs_preview then
    self:open_preview(nil, {})
    self._initialized_preview = needs_preview
  end
end

function UI.scroll(self, offset, search_offset)
  if search_offset then
    for i, item in ipairs(self._collector.items:values()) do
      local found = search_offset(item)
      if found then
        offset = i - 1
        break
      end
    end
  end
  if offset ~= 0 then
    self:update_offset(offset)
    self._item_list:set_row(self._state.row)
  end
end

function UI.resume(self)
  self:close(true)
  self:open(false, self._on_move, self._initialized_preview)
  return self:redraw(self._collector.input_lines, self._state.row)
end

function UI._highlight_item_list_win(_, _, bufnr, topline, botline_guess)
  local ctx, err = Context.get_from_path(bufnr, "$")
  if err ~= nil then
    return false
  end
  ctx.ui:highlight_item_list(topline, botline_guess)
  return false
end

function UI.highlight_item_list(self, first_line, last_line)
  local collector_items = self._collector.items:values()
  local raw_items = {}
  for i = first_line + 1, last_line, 1 do
    table.insert(raw_items, collector_items[i])
  end

  local source = self._collector.source
  local filters = self._collector.filters
  local filter_ctxs = self._collector.items.filter_ctxs
  local source_ctx = self._collector.source_ctx
  self._item_list:highlight(first_line, raw_items, source, filters, filter_ctxs, source_ctx)
end

function UI._highlight_inputter_win(_, _, bufnr, topline, botline_guess)
  local ctx, err = Context.get_from_path(bufnr, "%-input$")
  if err ~= nil then
    return false
  end
  ctx.ui:highlight_inputter(topline, botline_guess)
  return false
end

function UI.highlight_inputter(self)
  local filters = self._collector.filters:values()
  self._inputter:highlight(filters)
end

function UI.redraw(self, input_lines, row)
  if self._item_list:is_valid() then
    local filters = self._collector.filters:values()
    local sorters = self._collector.sorters:values()
    local source = self._collector.source
    local result_count = self._collector:all_count()
    local items = self._collector.items:values()
    local start_index = self._collector.items.start_index
    local end_index = self._collector.items.end_index
    local finished = self._collector:finished()

    self._item_list:redraw(items)
    self._status_line:redraw(source, sorters, finished, start_index, end_index, result_count)
    self._inputter:redraw(input_lines, filters)
  end

  if row ~= nil then
    -- NOTE: Should set the row after redrawing. redrawing resets cursor.
    self._item_list:set_row(row)
  end

  local err = self:on_move()
  if err ~= nil then
    return err
  end

  UI._changed_after(input_lines)
end

function UI.on_move(self)
  local items = self:selected_items()
  return self._debounced_on_move(items)
end

function UI.update_offset(self, offset)
  self._state = self._state:update_row(offset, self._collector.items:length(), self._collector.items.display_limit)
end

function UI.close(self, is_passive, immediately)
  if self._item_list == nil or not self._item_list:is_valid() then
    return
  end

  if not immediately then
    self._collector:discard()
  end

  local current_window = vim.api.nvim_get_current_win()
  local origin_window, new_state = self._state:save(self._item_list, self._inputter)
  self._state = new_state

  self._item_list:close(is_passive)
  self._inputter:close()
  self._status_line:close()
  self:close_preview()

  vim.api.nvim_set_decoration_provider(_item_list_ns, {})
  vim.api.nvim_set_decoration_provider(_inputter_ns, {})

  if vim.api.nvim_win_is_valid(current_window) then
    vim.api.nvim_set_current_win(current_window)
  elseif vim.api.nvim_win_is_valid(origin_window) then
    vim.api.nvim_set_current_win(origin_window)
  end

  vim.cmd.redraw() -- HACK: not to draw incomplete windows
end

function UI.into_list(self)
  self._item_list:enter()
end

function UI.into_inputter(self)
  self._inputter:enter()
  self._item_list:enable_cursorline()
end

function UI.current_position_filter(self)
  local cursor = self._inputter:cursor()
  return self._collector.filters[cursor[1]]
end

function UI.append_input(self, input_line)
  self._inputter:append(input_line)
end

function UI.recall_history(self, offset)
  self._inputter:recall_history(offset)
end

function UI.start_insert(self, behavior)
  self._inputter:start_insert(behavior)
end

function UI.selected_items(self, action_name, range)
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
  if self._item_list:is_valid() then
    index = self._item_list:cursor()[1]
  else
    index = self._state.row
  end
  return { self._collector.items[index] }
end

function UI.open_preview(self, item, open_target)
  if not self._item_list:is_valid() then
    return
  end

  local pos = self._item_list:position()
  local height = pos.height + self._inputter:height() + 1
  local width = self:_width()
  local left_column = 2
  local row = pos.row

  self:_move_to(left_column)
  self._sidecar:open(item, open_target, width, height, row, left_column)
end

function UI.exists_same_preview(self, items)
  return self._sidecar:exists_same(items[1])
end

function UI.close_preview(self)
  self._sidecar:close()
  if self._item_list:is_valid() then
    self:_move_to(self:_column())
  end
end

function UI.redraw_selections(self, s, e)
  return self._item_list:redraw_selections(s, e)
end

function UI.has_window(self, id)
  return self._item_list:has(id) or self._inputter:has(id) or self._status_line:has(id)
end

function UI._move_to(self, left_column)
  self._item_list:move_to(left_column)
  self._inputter:move_to(left_column)
  self._status_line:move_to(left_column)
end

function UI._height()
  return math.floor(vim.o.lines * 0.5)
end

function UI._width()
  return math.floor(vim.o.columns * 0.6)
end

function UI._row(self, input_lines)
  return (vim.o.lines - self:_height() - #input_lines) / 2
end

function UI._column(self)
  return (vim.o.columns - self:_width()) / 2
end

-- for testing
function UI._changed_after(_) end

local setup_highlight_groups = function()
  ItemList.setup_highlight_groups()
  vim.api.nvim_set_hl(0, "ThettoSelected", { default = true, link = "Statement" })
  vim.api.nvim_set_hl(0, "ThettoInfo", { default = true, link = "StatusLine" })
  vim.api.nvim_set_hl(0, "ThettoColorLabelOthers", { default = true, link = "StatusLine" })
  vim.api.nvim_set_hl(0, "ThettoColorLabelBackground", { default = true, link = "NormalFloat" })
  vim.api.nvim_set_hl(0, "ThettoInput", { default = true, link = "NormalFloat" })
  vim.api.nvim_set_hl(0, "ThettoPreview", { default = true, link = "Search" })
  vim.api.nvim_set_hl(0, "ThettoFilterInfo", { default = true, link = "Comment" })
end

local group = vim.api.nvim_create_augroup("thetto", {})
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = group,
  pattern = { "*" },
  callback = setup_highlight_groups,
})

setup_highlight_groups()

return UI
