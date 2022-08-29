local Source = require("thetto.core.items.source")
local SourceContext = require("thetto.core.items.source_context")
local SourceResult = require("thetto.core.items.source_result")
local Items = require("thetto.core.items")
local Filters = require("thetto.core.items.filters")
local Sorters = require("thetto.core.items.sorters")
local wraplib = require("thetto.lib.wrap")
local listlib = require("thetto.lib.list")
local vim = vim

local Collector = {}
Collector.__index = Collector

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
    source = source,
    selected = {},
    filters = filters,
    sorters = sorters,
    input_lines = listlib.fill(opts.input_lines, #source.filters, ""),
    source_ctx = SourceContext.new(
      opts.pattern,
      opts.cwd,
      opts.debounce_ms,
      opts.throttle_ms,
      opts.range,
      filters:has_interactive(),
      vim.api.nvim_get_current_buf()
    ),
    _result = SourceResult.zero(),
    _ignorecase = opts.ignorecase,
    _smartcase = opts.smartcase,
  }
  local self = setmetatable(tbl, Collector)
  self.items = self:_items(0, nil, opts.display_limit)

  self.update_with_throttle = wraplib.throttle_with_last(opts.throttle_ms, function(_, callback)
    local update_err = self:update()
    if callback then
      callback()
    end
    return update_err
  end)

  self._send_redraw_event = function() end

  self._send_redraw_selection_event = function() end

  return self, nil
end

function Collector.subscribe_input(self, immediately, input_observable, get_lines)
  self.update_with_throttle = wraplib.throttle_with_last(self.source_ctx.throttle_ms, function(_, callback)
    local input_lines = get_lines()
    if input_lines then
      self.input_lines = input_lines
    end
    local err = self:update()
    if callback then
      callback()
    end
    return err
  end)
  local update_with_debounce = wraplib.debounce(self.source_ctx.debounce_ms, function()
    return self:update_with_throttle()
  end)
  input_observable:subscribe({
    next = function()
      update_with_debounce()
    end,
    complete = function()
      if immediately then
        return
      end
      self:discard()
    end,
  })
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

function Collector.start(self, input_pattern, resolve, reject)
  resolve = resolve or function() end
  reject = reject or function() end

  local source_ctx = self.source_ctx:from(input_pattern or self.source_ctx.pattern)
  local result, err = self.source:collect(source_ctx)
  if err then
    return err
  end

  self._result = result
  self.source_ctx = source_ctx

  local start_err = self._result:start({
    next = function(items)
      self._result:append(items)
      return self:update_with_throttle()
    end,
    error = function(e)
      require("thetto.vendor.misclib.message").warn(e)
      return self:update_with_throttle(function()
        reject(e)
      end)
    end,
    complete = function()
      return self:update_with_throttle(resolve)
    end,
  })
  if start_err then
    return start_err
  end

  return nil
end

function Collector.wait(self, ms)
  return self._result:wait(ms)
end

function Collector.discard(self)
  return self._result:discard()
end

function Collector.finished(self)
  return self._result:finished()
end

function Collector.all_count(self)
  return self._result:count()
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

function Collector.change_page_offset(self, page_offset)
  return self:_update_items(page_offset)
end

function Collector.change_display_limit(self, offset)
  return self:_update_items(nil, self.items.display_limit + offset)
end

function Collector._update_sorters(self, sorters)
  self.sorters = sorters
  return self:_update_items()
end

function Collector.update(self)
  self._result:apply_selected(self.items)
  return self:_update_items()
end

function Collector._items(self, page, page_offset, display_limit)
  return Items.new(
    self._result,
    self.input_lines,
    self.filters,
    self.sorters,
    self._ignorecase,
    self._smartcase,
    display_limit or self.items.display_limit,
    page or self.items.page,
    page_offset
  )
end

function Collector._update_items(self, page_offset, display_limit)
  self.items = self:_items(nil, page_offset, display_limit)

  if not self.source_ctx.interactive then
    return self:_send_redraw_event()
  end

  local input_pattern = self.filters:extract_interactive(self.input_lines)
  if self.source_ctx.pattern == input_pattern then
    return self:_send_redraw_event()
  end

  self:discard()

  local err = self:start(input_pattern)
  if err then
    return err
  end
  return self:_send_redraw_event()
end

return Collector
