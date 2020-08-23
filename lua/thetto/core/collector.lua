local source_core = require("thetto/core/source")
local filter_core = require "thetto/core/filter"
local sorter_core = require "thetto/core/sorter"
local modulelib = require "thetto/lib/module"
local inputs = require "thetto/input"
local wraplib = require "thetto/lib/wrap"
local repository = require("thetto/core/repository")

local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.start(self)
  self.all_items, self.job = self.source:collect(self.opts)
  for i, item in ipairs(self.all_items) do
    item.index = i
  end

  if self.job == nil and #self.all_items == 0 and not self.opts.allow_empty then
    return self.source.name .. ": empty"
  end

  if self.job ~= nil then
    self.job:start()
  end

  return nil
end

function Collector.update(self, input_lines)
  input_lines = input_lines or {}
  self.opts = vim.deepcopy(self.original_opts)
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
end

function Collector.toggle_all_selections(self)
  self:toggle_selections(self.items)
end

function Collector.add_filter(self, name)
  table.insert(self._filter_names, name)
  self:update_filters(self._filter_names)
end

function Collector._target_filter_index(self, names, name)
  local filter, err = filter_core.create(name, self.opts)
  if err ~= nil then
    return nil, err
  end
  for i, n in ipairs(names) do
    if n == filter.name then
      return i, nil
    end
  end
  return nil, "not found filter: " .. name
end

function Collector._target_sorter_index(_, names, name)
  local sorter, err = sorter_core.create(name)
  if err ~= nil then
    return nil, err
  end
  for i, n in ipairs(names) do
    if n == sorter.name then
      return i, nil
    end
  end
  return nil, "not found sorter: " .. name
end

function Collector.remove_filter(self, name)
  if #self._filter_names <= 1 then
    return "the last filter cannot be removed"
  end

  local index, err = self:_target_filter_index(self._filter_names, name)
  if err ~= nil then
    return err
  end

  table.remove(self._filter_names, index)
  self:update_filters(self._filter_names)
end

function Collector.inverse_filter(self, name)
  local index, err = self:_target_filter_index(self._filter_names, name)
  if err ~= nil then
    return err
  end

  local filter = self.filters[index]
  filter.inverse = not filter.inverse
  self._filter_names[index] = filter:get_name()
  self:update_filters(self._filter_names)
end

function Collector.change_filter(self, old, new)
  local index, err = self:_target_filter_index(self._filter_names, old)
  if err ~= nil then
    return err
  end

  local filter, ferr = filter_core.create(new, self.opts)
  if ferr ~= nil then
    return nil, ferr
  end

  self._filter_names[index] = filter:get_name()
  self:update_filters(self._filter_names)
end

function Collector.reverse_sorter(self, name)
  local index, err = self:_target_sorter_index(self._sorter_names, name)
  if err ~= nil then
    return err
  end

  local sorter = self.sorters[index]
  sorter.reverse = not sorter.reverse
  self._sorter_names[index] = sorter:get_name()
  self:update_sorters(self._sorter_names)
end

function Collector._update_all_items(self, items)
  local len = #self.all_items
  for i, item in ipairs(items) do
    item.index = len + i
  end
  vim.list_extend(self.all_items, items)

  local err = self.notifier:send("update_input")
  if err ~= nil then
    return err
  end
  self.is_finished = not self.job:is_running()
  return nil
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
  return self.is_finished
end

function Collector.update_filters(self, names)
  self:_update_filters(names)
  self:_update_items(self._input_lines)
  return self.notifier:send("update_items", self._input_lines)
end

function Collector.update_sorters(self, names)
  self:_update_sorters(names)
  self:_update_items(self._input_lines)
  return self.notifier:send("update_items", self._input_lines)
end

function Collector._update_filters(self, names)
  local filters = {}
  local new_names = {}
  for _, name in ipairs(names) do
    local filter, err = filter_core.create(name, self.opts)
    if err ~= nil then
      return err
    end
    table.insert(filters, filter)
    table.insert(new_names, filter:get_name())
  end

  self.filters = filters
  self._filter_names = new_names

  return nil
end

function Collector._update_sorters(self, names)
  local sorters = {}
  local new_names = {}
  for _, name in ipairs(names) do
    local sorter, err = sorter_core.create(name)
    if err ~= nil then
      return err
    end
    table.insert(sorters, sorter)
    table.insert(new_names, sorter:get_name())
  end

  self.sorters = sorters
  self._sorter_names = new_names

  return nil
end

function Collector._update_items(self, input_lines)
  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in ipairs(self.all_items) do
    table.insert(items, item)
  end

  for i, filter in ipairs(self.filters) do
    local input_line = input_lines[i]
    if input_line ~= nil and input_line ~= "" then
      items = filter:apply(items, input_line, self.opts)
    end
  end
  for _, sorter in ipairs(self.sorters) do
    items = sorter:apply(items)
  end

  local filtered = {}
  for i = 1, self.opts.display_limit, 1 do
    filtered[i] = items[i]
  end

  self.items = filtered
end

M.create = function(notifier, source_name, source_opts, action_opts, opts)
  opts.cwd = vim.fn.expand(opts.cwd)
  if opts.cwd == "." then
    opts.cwd = vim.fn.fnamemodify(".", ":p")
  end
  if opts.cwd ~= "/" and vim.endswith(opts.cwd, "/") then
    opts.cwd = opts.cwd:sub(1, #opts.cwd - 1)
  end

  if opts.target ~= nil then
    local target = modulelib.find_target(opts.target)
    if target == nil then
      return nil, "not found target: " .. opts.target
    end
    opts.cwd = target.cwd()
  end

  if opts.pattern_type ~= nil then
    local pattern = inputs.get(opts.pattern_type)
    if pattern == nil then
      return nil, "not found pattern type: " .. opts.pattern_type
    end
    opts.pattern = pattern
  end

  local source, err = source_core.create(notifier, source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end

  local filters = {}
  local sorters = {}
  local collector_tbl = {
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
    is_finished = false,
    _filter_names = source.filters,
    _sorter_names = source.sorters,
    _input_lines = {},
  }
  local collector = setmetatable(collector_tbl, Collector)

  err = collector:_update_filters(source.filters)
  if err ~= nil then
    return nil, err
  end
  err = collector:_update_sorters(source.sorters)
  if err ~= nil then
    return nil, err
  end

  local update = wraplib.debounce(opts.debounce_ms, function()
    return collector:update(collector._input_lines)
  end)
  notifier:on("update_input", function(lines)
    collector._input_lines = lines
    return update()
  end)
  notifier:on("update_all_items", function(items)
    return collector:_update_all_items(items)
  end)
  notifier:on("finish", function()
    return collector:stop()
  end)

  return collector, nil
end

M._to_key = function(names)
  return table.concat(names, ",")
end

M.resume = function(source_name)
  local ctx, err = repository.get(source_name)
  if err ~= nil then
    return nil, err
  end
  return ctx.collector, nil
end

return M
