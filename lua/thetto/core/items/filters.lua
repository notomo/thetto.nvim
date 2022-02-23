local Filter = require("thetto.core.items.filter")
local vim = vim

local Filters = {}

function Filters.new(names, opts)
  vim.validate({ names = { names, "table" }, opts = { opts, "table" } })
  local filters = {}
  for _, name in ipairs(names) do
    local filter, err = Filter.parse(name, opts)
    if err ~= nil then
      return nil, err
    end
    table.insert(filters, filter)
  end

  local tbl = { _filters = filters }
  return setmetatable(tbl, Filters)
end

function Filters.__index(self, k)
  if type(k) == "number" then
    return self._filters[k]
  end
  return Filters[k]
end

local DISABLED_FILTER_ERR = "filter is disabled: "

function Filters._find(self, name, opts)
  local f, err = Filter.parse(name, opts)
  if err ~= nil then
    return nil, nil, err
  end
  for i, filter in ipairs(self._filters) do
    if filter == f then
      return filter, i, nil
    end
  end
  return nil, nil, DISABLED_FILTER_ERR .. name
end

function Filters._names(self)
  return vim.tbl_map(function(filter)
    return filter.name
  end, self._filters)
end

function Filters.inverse(self, name, opts)
  local filter, index, err = self:_find(name, opts)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  names[index] = filter:inverse().name

  return Filters.new(names, opts), nil
end

function Filters.add(self, name, opts)
  local filter, err = Filter.parse(name, opts)
  if err ~= nil then
    return nil, err
  end
  local names = self:_names()
  table.insert(names, filter.name)
  return Filters.new(names, opts), nil
end

function Filters.remove(self, name, opts)
  if #self._filters <= 1 then
    return nil, "the last filter cannot be removed"
  end

  local _, index, err = self:_find(name, opts)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  table.remove(names, index)
  return Filters.new(names, opts), nil
end

function Filters.change(self, old, new, opts)
  local _, index, err = self:_find(old, opts)
  if err ~= nil then
    return nil, err
  end

  local filter, ferr = Filter.parse(new, opts)
  if ferr ~= nil then
    return nil, ferr
  end

  local names = self:_names()
  names[index] = filter.name
  return Filters.new(names, opts), nil
end

function Filters.has_interactive(self)
  return #(vim.tbl_filter(function(filter)
    return filter.is_interactive
  end, self._filters)) > 0
end

function Filters.values(self)
  return self._filters
end

function Filters.apply(self, items, input_lines, opts)
  for i, filter in ipairs(self._filters) do
    local input_line = input_lines[i]
    if input_line ~= nil and input_line ~= "" then
      items = filter:apply(items, input_line, opts)
    end
  end
  return items
end

function Filters.extract_interactive(self, input_lines)
  for i, filter in ipairs(self._filters) do
    if filter.is_interactive then
      return input_lines[i]
    end
  end
end

return Filters
