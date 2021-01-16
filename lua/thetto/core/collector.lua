local Source = require("thetto/core/source").Source
local Filters = require("thetto/core/filter").Filters
local Sorters = require("thetto/core/sorter").Sorters
local wraplib = require("thetto/lib/wrap")
local vim = vim

local M = {}

local Collector = {}
Collector.__index = Collector
M.Collector = Collector

function Collector.new(notifier, source_name, source_opts, opts)
  local source, err = Source.new(notifier, source_name, source_opts, opts)
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
    all_items = {},
    job = nil,
    source = source,
    original_opts = opts,
    opts = vim.deepcopy(opts),
    items = {},
    selected = {},
    filters = filters,
    sorters = sorters,
    notifier = notifier,
    input_lines = vim.fn["repeat"]({""}, #source.filters),
  }
  local self = setmetatable(tbl, Collector)
  self.opts.interactive = self.filters:has_interactive()

  self._update_with_debounce = wraplib.debounce(opts.debounce_ms, function()
    if self._input_bufnr ~= nil and vim.api.nvim_buf_is_valid(self._input_bufnr) then
      local input_lines = vim.api.nvim_buf_get_lines(self._input_bufnr, 0, -1, true)
      self.input_lines = input_lines
    end
    return self:update()
  end)

  notifier:on("setup_input", function(bufnr)
    self._input_bufnr = bufnr
  end)
  notifier:on("update_input", function()
    return self._update_with_debounce()
  end)
  notifier:on("update_all_items", function(items)
    return self:_update_all_items(items)
  end)
  notifier:on("finish", function()
    return self:discard()
  end)

  return self, nil
end

function Collector.start(self)
  local all_items, job, err = self.source:collect(self.opts)
  if err ~= nil and err ~= Source.errors.skip_empty_pattern then
    return err
  end
  self.all_items = all_items
  self.job = job

  for i, item in ipairs(self.all_items) do
    item.index = i
  end

  local interactive_skip_empty = self.opts.interactive and err == Source.errors.skip_empty_pattern
  if not interactive_skip_empty and self.job == nil and #self.all_items == 0 and not self.opts.allow_empty then
    return self.source.name .. ": empty"
  end

  if self.job ~= nil then
    local joberr = self.job:start()
    if joberr ~= nil then
      return joberr
    end
  end

  return nil
end

function Collector.wait(self, ms)
  ms = ms or 1000
  return vim.wait(ms, function()
    return self:finished()
  end, 10)
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

  for _, item in ipairs(self.items) do
    if item.selected ~= nil then
      self.all_items[item.index].selected = item.selected
    end
  end

  self:_update_items(input_lines)

  return self.notifier:send("update_items", input_lines)
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
  self.notifier:send("update_selected")
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
  return self.notifier:send("update_items", self.input_lines)
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
  return self.notifier:send("update_items", self.input_lines)
end

function Collector._update_all_items(self, items)
  local len = #self.all_items
  for i, item in ipairs(items) do
    item.index = len + i
  end
  vim.list_extend(self.all_items, items)

  local err = self._update_with_debounce()
  if err ~= nil then
    return err
  end
  return nil
end

function Collector.discard(self)
  if self.job ~= nil then
    self.job:discard()
  end
end

function Collector.stop(self)
  if self.job ~= nil then
    self.job:stop()
  end
end

function Collector.finished(self)
  if self.job == nil then
    return true
  end
  return not self.job:is_running()
end

function Collector._update_items(self, input_lines)
  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in ipairs(self.all_items) do
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
