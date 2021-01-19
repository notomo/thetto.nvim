local Source = require("thetto/core/source").Source
local SourceResult = require("thetto/core/source_result").SourceResult
local Filters = require("thetto/core/filter").Filters
local Sorters = require("thetto/core/sorter").Sorters
local wraplib = require("thetto/lib/wrap")
local vim = vim

local M = {}

local Collector = {}
Collector.__index = Collector
M.Collector = Collector

function Collector.new(source_name, source_opts, opts)
  local source, err = Source.new(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end

  local filters, ferr = Filters.new(source.filters, opts)
  if ferr ~= nil then
    return nil, ferr
  end

  local sorters, serr = Sorters.new(source.sorters)
  if serr ~= nil then
    return nil, serr
  end

  local tbl = {
    result = SourceResult.new(source.name),
    source = source,
    original_opts = opts,
    opts = vim.deepcopy(opts),
    items = {},
    selected = {},
    filters = filters,
    sorters = sorters,
    input_lines = vim.fn["repeat"]({""}, #source.filters),
  }
  local self = setmetatable(tbl, Collector)
  self.opts.interactive = self.filters:has_interactive()

  self.update_with_debounce = wraplib.debounce(opts.debounce_ms, function()
    return self:update()
  end)

  self._send_redraw_event = function()
  end

  self._send_redraw_selection_event = function()
  end

  return self, nil
end

function Collector.attach(self, input_bufnr)
  vim.validate({input_bufnr = {input_bufnr, "number"}})
  local on_input = function()
    if vim.api.nvim_buf_is_valid(input_bufnr) then
      self.input_lines = vim.api.nvim_buf_get_lines(input_bufnr, 0, -1, true)
    end
    return self:update()
  end
  self.update_with_debounce = wraplib.debounce(self.opts.debounce_ms, on_input)
end

function Collector.attach_ui(self, ui)
  vim.validate({ui = {ui, "table"}})
  self._send_redraw_event = function(_, input_lines)
    return ui:redraw(input_lines)
  end
  self._send_redraw_selection_event = function()
    return ui.windows:redraw_selections(self)
  end
end

function Collector.start(self)
  local on_update_job = function(items)
    self.result:append(items)
    return self:update_with_debounce()
  end

  local result, err = self.source:collect(self.opts, on_update_job)
  if err ~= nil then
    return err
  end
  self.result = result

  return nil
end

function Collector.wait(self, ms)
  return self.result:wait(ms)
end

function Collector.discard(self)
  return self.result:discard()
end

function Collector.stop(self)
  return self.result:stop()
end

function Collector.finished(self)
  return self.result:finished()
end

function Collector.toggle_selections(self, items)
  for _, item in ipairs(items) do
    local key = tostring(item.index)
    if self.selected[key] then
      self.selected[key] = nil
    else
      self.selected[key] = item
    end

    for _, filtered_item in ipairs(self.items) do
      if filtered_item.index == item.index then
        filtered_item.selected = not filtered_item.selected
        break
      end
    end
  end
  self:_send_redraw_selection_event()
end

function Collector.toggle_all_selections(self)
  self:toggle_selections(self.items)
end

function Collector.add_filter(self, name)
  local filters, err = self.filters:add(name, self.opts)
  if err ~= nil then
    return err
  end
  self:_update_filters(filters)
end

function Collector.remove_filter(self, name)
  local filters, err = self.filters:remove(name, self.opts)
  if err ~= nil then
    return err
  end
  self:_update_filters(filters)
end

function Collector.inverse_filter(self, name)
  local filters, err = self.filters:inverse(name, self.opts)
  if err ~= nil then
    return err
  end
  self:_update_filters(filters)
end

function Collector.change_filter(self, old, new)
  local filters, err = self.filters:change(old, new, self.opts)
  if err ~= nil then
    return err
  end
  self:_update_filters(filters)
end

function Collector._update_filters(self, filters)
  self.filters = filters
  self.opts.interactive = self.filters:has_interactive()
  self:_update_items(self.input_lines)
  return self:_send_redraw_event(self.input_lines)
end

function Collector.reverse_sorter(self, name)
  local sorters, err = self.sorters:reverse(name)
  if err ~= nil then
    return err
  end
  self:_update_sorters(sorters)
end

function Collector.toggle_sorter(self, name)
  local sorters, err = self.sorters:toggle(name)
  if err ~= nil then
    return err
  end
  self:_update_sorters(sorters)
end

function Collector._update_sorters(self, sorters)
  self.sorters = sorters
  self:_update_items(self.input_lines)
  return self:_send_redraw_event(self.input_lines)
end

function Collector.update(self)
  local input_lines = self.input_lines
  local pattern = self.opts.pattern
  local interactive = self.opts.interactive

  self.opts = vim.deepcopy(self.original_opts)
  self.opts.pattern = pattern
  self.opts.interactive = interactive
  if not self.opts.ignorecase and self.opts.smartcase and table.concat(input_lines, ""):find("[A-Z]") then
    self.opts.ignorecase = false
  else
    self.opts.ignorecase = true
  end

  self.result:apply_selected(self.items)
  self:_update_items(input_lines)

  return self:_send_redraw_event(input_lines)
end

function Collector._update_items(self, input_lines)
  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in self.result:iter() do
    table.insert(items, item)
  end

  for i, filter in self.filters:iter() do
    local input_line = input_lines[i]
    if input_line ~= nil and input_line ~= "" then
      items = filter:apply(items, input_line, self.opts)
    end
  end
  for _, sorter in self.sorters:iter() do
    items = sorter:apply(items)
  end

  local filtered = {}
  for i = 1, self.opts.display_limit, 1 do
    filtered[i] = items[i]
  end

  self.items = filtered

  if not self.opts.interactive then
    return
  end

  local input = nil
  for i, filter in self.filters:iter() do
    if filter.is_interactive then
      input = input_lines[i]
      break
    end
  end

  if self.opts.pattern == input then
    return
  end
  self.opts.pattern = input

  self:discard()

  local err = self:start()
  if err ~= nil then
    return err
  end
end

return M
