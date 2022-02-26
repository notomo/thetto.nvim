local Source = require("thetto.core.source").Source
local SourceContext = require("thetto.core.source_context")
local SourceResult = require("thetto.core.source_result").SourceResult
local Items = require("thetto.core.items")
local Filters = require("thetto.core.items.filters")
local Sorters = require("thetto.core.items.sorters")
local wraplib = require("thetto.lib.wrap")
local listlib = require("thetto.lib.list")
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

  local modifier_factory = require("thetto.core.items.filter_modifier_factory").new(opts.cwd)
  local filters, ferr = Filters.new(source.filters, modifier_factory)
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
    selected = {},
    filters = filters,
    sorters = sorters,
    input_lines = listlib.fill(opts.input_lines, #source.filters, ""),
    _source_ctx = SourceContext.new(
      opts.pattern,
      opts.cwd,
      opts.debounce_ms,
      opts.allow_empty,
      filters:has_interactive()
    ),
    _ignorecase = opts.ignorecase,
    _smartcase = opts.smartcase,
    _display_limit = opts.display_limit,
  }
  tbl.items = Items.new(
    tbl.result,
    tbl.input_lines,
    filters,
    sorters,
    tbl._ignorecase,
    tbl._smartcase,
    tbl._display_limit
  )
  local self = setmetatable(tbl, Collector)

  self.update_with_debounce = wraplib.debounce(opts.debounce_ms, function()
    return self:update()
  end)

  self._send_redraw_event = function() end

  self._send_redraw_selection_event = function() end

  return self, nil
end

function Collector.attach(self, input_bufnr)
  vim.validate({ input_bufnr = { input_bufnr, "number" } })
  local on_input = function()
    if vim.api.nvim_buf_is_valid(input_bufnr) then
      self.input_lines = vim.api.nvim_buf_get_lines(input_bufnr, 0, -1, true)
    end
    return self:update()
  end
  self.update_with_debounce = wraplib.debounce(self._source_ctx.debounce_ms, on_input)
end

function Collector.attach_ui(self, ui)
  vim.validate({ ui = { ui, "table" } })
  self._send_redraw_event = function()
    return ui:redraw(self.input_lines)
  end
  self._send_redraw_selection_event = function(_, s, e)
    return ui:redraw_selections(s, e)
  end
end

function Collector.start(self, input_pattern)
  local on_update_job = function(items)
    self.result:append(items)
    return self:update_with_debounce()
  end
  local reset = function()
    self.result:reset()
  end

  local source_ctx = self._source_ctx:from(input_pattern or self._source_ctx.pattern)
  local result, err = self.source:collect(source_ctx, on_update_job, reset)
  if err ~= nil then
    return err
  end
  self.result = result
  self._source_ctx = source_ctx

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
  local rows = {}
  for _, item in ipairs(items) do
    local key = tostring(item.index)
    if self.selected[key] then
      self.selected[key] = nil
    else
      self.selected[key] = item
    end

    for row, filtered_item in self.items:iter() do
      if filtered_item.index == item.index then
        table.insert(rows, row)
        filtered_item.selected = not filtered_item.selected
        break
      end
    end
  end
  self:_send_redraw_selection_event(rows[1] - 1, rows[#rows])
end

function Collector.toggle_all_selections(self)
  self:toggle_selections(self.items:values())
end

function Collector.add_filter(self, name)
  local filters, err = self.filters:add(name)
  if err ~= nil then
    return err
  end
  return self:_update_filters(filters)
end

function Collector.remove_filter(self, name)
  local filters, err = self.filters:remove(name)
  if err ~= nil then
    return err
  end
  return self:_update_filters(filters)
end

function Collector.inverse_filter(self, name)
  local filters, err = self.filters:inverse(name)
  if err ~= nil then
    return err
  end
  return self:_update_filters(filters)
end

function Collector.change_filter(self, old, new)
  local filters, err = self.filters:change(old, new)
  if err ~= nil then
    return err
  end
  return self:_update_filters(filters)
end

function Collector._update_filters(self, filters)
  self.filters = filters
  return self:_update_items()
end

function Collector.reverse_sorter(self, name)
  local sorters, err = self.sorters:reverse(name)
  if err ~= nil then
    return err
  end
  return self:_update_sorters(sorters)
end

function Collector.toggle_sorter(self, name)
  local sorters, err = self.sorters:toggle(name)
  if err ~= nil then
    return err
  end
  return self:_update_sorters(sorters)
end

function Collector._update_sorters(self, sorters)
  self.sorters = sorters
  return self:_update_items()
end

function Collector.update(self)
  self.result:apply_selected(self.items)
  return self:_update_items()
end

function Collector._update_items(self)
  self.items = Items.new(
    self.result,
    self.input_lines,
    self.filters,
    self.sorters,
    self._ignorecase,
    self._smartcase,
    self._display_limit
  )

  if not self._source_ctx.interactive then
    return self:_send_redraw_event()
  end

  local input_pattern = self.filters:extract_interactive(self.input_lines)
  if self._source_ctx.pattern == input_pattern then
    return self:_send_redraw_event()
  end

  self:discard()

  local err = self:start(input_pattern)
  if err then
    return err
  end
  return self:_send_redraw_event()
end

return M
