local source_core = require("thetto/core/source")
local filter_core = require "thetto/core/filter"
local sorter_core = require "thetto/core/sorter"
local modulelib = require "thetto/lib/module"
local inputs = require "thetto/input"

local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.start(self, on_update)
  self.source.append = function(items)
    local len = #self.all_items
    for i, item in ipairs(items) do
      item.index = len + i
    end
    vim.list_extend(self.all_items, items)
    on_update()
  end

  self.all_items, self.job = self.source:collect(self.opts)
  for i, item in ipairs(self.all_items) do
    item.index = i
  end

  if self.job == nil and #self.all_items == 0 and not self.opts.allow_empty then
    return self.source.name .. ": empty"
  end

  return nil
end

function Collector.update(self, input_lines, filter_names, sorter_names)
  self.opts = vim.deepcopy(self.original_opts)
  if not self.opts.ignorecase and self.opts.smartcase and table.concat(input_lines, ""):find("[A-Z]") then
    self.opts.ignorecase = false
  else
    self.opts.ignorecase = true
  end

  do
    local filters, err = M._get_filters(filter_names, self.opts)
    if err ~= nil then
      return err
    end
    self.filters = filters
  end

  do
    local sorters, err = M._get_sorters(sorter_names)
    if err ~= nil then
      return err
    end
    self.sorters = sorters
  end

  for _, item in ipairs(self.items) do
    if item.selected ~= nil then
      self.all_items[item.index].selected = item.selected
    end
  end

  self.items = M._modify_items(self.all_items, self.filters, input_lines, self.sorters, self.opts)

  return nil
end

function Collector.start_job(self)
  if self.job ~= nil then
    self.job:start()
  end
end

function Collector.stop(self)
  if self.job ~= nil then
    self.job:stop()
  end
end

M.create = function(source_name, source_opts, opts)
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

  local source, err = source_core.create(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local collector = {
    all_items = {},
    job = nil,
    source = source,
    original_opts = opts,
    opts = vim.deepcopy(opts),
    items = {},
    sorters = {},
    filters = {},
  }
  return setmetatable(collector, Collector), nil
end

M._modify_items = function(all_items, filters, input_lines, sorters, opts)
  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in ipairs(all_items) do
    table.insert(items, item)
  end

  for i, filter in ipairs(filters) do
    local input_line = input_lines[i]
    if input_line ~= nil and input_line ~= "" then
      items = filter:apply(items, input_line, opts)
    end
  end
  for _, sorter in ipairs(sorters) do
    items = sorter:apply(items)
  end

  local filtered = {}
  for i = 1, opts.display_limit, 1 do
    filtered[i] = items[i]
  end
  return filtered
end

M._get_filters = function(names, opts)
  local filters = {}
  for _, name in ipairs(names) do
    local filter, err = filter_core.create(name, opts)
    if err ~= nil then
      return nil, err
    end
    table.insert(filters, filter)
  end
  return filters, nil
end

M._get_sorters = function(names)
  local sorters = {}
  for _, name in ipairs(names) do
    local sorter, err = sorter_core.create(name)
    if err ~= nil then
      return nil, err
    end
    table.insert(sorters, sorter)
  end
  return sorters, nil
end

return M
