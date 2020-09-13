local source_core = require("thetto/core/source")
local filter_core = require("thetto/core/filter")
local sorter_core = require("thetto/core/sorter")
local modulelib = require("thetto/lib/module")
local inputs = require("thetto/core/input")
local wraplib = require("thetto/lib/wrap")

local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.start(self)
  local all_items, job, err = self.source:collect(self.opts)
  if err ~= nil and err ~= source_core.errors.skip_empty_pattern then
    return err
  end
  self.all_items = all_items
  self.job = job

  for i, item in ipairs(self.all_items) do
    item.index = i
  end

  local interactive_skip_empty = self.opts.interactive and err == source_core.errors.skip_empty_pattern
  if not interactive_skip_empty and self.job == nil and #self.all_items == 0 and not self.opts.allow_empty then
    return self.source.name .. ": empty"
  end

  if self.job ~= nil then
    self.job:start()
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
  self._filter_names[index] = filter.name
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

  self._filter_names[index] = filter.name
  self:update_filters(self._filter_names)
end

function Collector.reverse_sorter(self, name)
  local index, err = self:_target_sorter_index(self._sorter_names, name)
  if err ~= nil then
    return err
  end

  local sorter = self.sorters[index]
  sorter.reverse = not sorter.reverse
  self._sorter_names[index] = sorter.name
  self:update_sorters(self._sorter_names)
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

function Collector.update_filters(self, names)
  self:_update_filters(names)
  self:_update_items(self.input_lines)
  return self.notifier:send("update_items", self.input_lines)
end

function Collector.update_sorters(self, names)
  self:_update_sorters(names)
  self:_update_items(self.input_lines)
  return self.notifier:send("update_items", self.input_lines)
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
    table.insert(new_names, filter.name)
  end

  self.filters = filters
  self._filter_names = new_names

  self.opts.interactive = #(vim.tbl_filter(function(filter)
    return filter.is_interactive
  end, self.filters)) > 0

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
    table.insert(new_names, sorter.name)
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

  if not self.opts.interactive then
    return
  end

  local input = nil
  for i, filter in ipairs(self.filters) do
    if filter.is_interactive then
      input = input_lines[i]
      break
    end
  end

  if self.opts.pattern == input then
    return
  end
  self.opts.pattern = input

  self:stop()

  local err = self:start()
  if err ~= nil then
    return err
  end
end

M.create = function(notifier, source_name, source_opts, opts)
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
    opts.cwd = target.cwd(opts.target_patterns)
  end

  if opts.pattern_type ~= nil then
    local pattern, err = inputs.get(opts.pattern_type)
    if err ~= nil then
      return nil, err
    end
    opts.pattern = pattern
  end

  local source, err = source_core.create(notifier, source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end

  local collector_tbl = {
    all_items = {},
    job = nil,
    source = source,
    original_opts = opts,
    opts = vim.deepcopy(opts),
    items = {},
    selected = {},
    filters = {},
    sorters = {},
    notifier = notifier,
    input_lines = vim.fn["repeat"]({""}, #source.filters),
    _filter_names = source.filters,
    _sorter_names = source.sorters,
  }
  local self = setmetatable(collector_tbl, Collector)

  err = self:_update_filters(source.filters)
  if err ~= nil then
    return nil, err
  end
  err = self:_update_sorters(source.sorters)
  if err ~= nil then
    return nil, err
  end

  self._update_with_debounce = wraplib.debounce(opts.debounce_ms, function(bufnr)
    if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
      local input_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
      self.input_lines = input_lines
    end
    return self:update()
  end)

  notifier:on("update_input", function(bufnr)
    return self._update_with_debounce(bufnr)
  end)
  notifier:on("update_all_items", function(items)
    return self:_update_all_items(items)
  end)
  notifier:on("finish", function()
    return self:stop()
  end)

  return self, nil
end

return M
