local Filter = require("thetto.core.items.filter")
local vim = vim

local Filters = {}

function Filters.new(names, modifier_factory)
  vim.validate({ names = { names, "table" }, modifier_factory = { modifier_factory, "table" } })
  local filters = {}
  for _, name in ipairs(names) do
    local filter, err = Filter.parse(name, modifier_factory)
    if err ~= nil then
      return nil, err
    end
    table.insert(filters, filter)
  end

  local tbl = { _filters = filters, _modifier_factory = modifier_factory }
  return setmetatable(tbl, Filters)
end

function Filters.__index(self, k)
  if type(k) == "number" then
    return self._filters[k]
  end
  return Filters[k]
end

local DISABLED_FILTER_ERR = "filter is disabled: "

function Filters._find(self, name)
  local f, err = Filter.parse(name, self._modifier_factory)
  if err ~= nil then
    return nil, nil, err
  end
  for i, filter in ipairs(self._filters) do
    if filter:equals(f) then
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

function Filters.inverse(self, name)
  local filter, index, err = self:_find(name)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  names[index] = filter:inverse().name
  return self:_update(names)
end

function Filters.add(self, name)
  local filter, err = Filter.parse(name, self._modifier_factory)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  table.insert(names, filter.name)
  return self:_update(names)
end

function Filters.remove(self, name)
  if #self._filters <= 1 then
    return nil, "the last filter cannot be removed"
  end

  local _, index, err = self:_find(name)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  table.remove(names, index)
  return self:_update(names)
end

function Filters.change(self, old, new)
  local _, index, err = self:_find(old)
  if err ~= nil then
    return nil, err
  end

  local filter, ferr = Filter.parse(new, self._modifier_factory)
  if ferr ~= nil then
    return nil, ferr
  end

  local names = self:_names()
  names[index] = filter.name
  return self:_update(names)
end

function Filters._update(self, names)
  return Filters.new(names, self._modifier_factory)
end

function Filters.has_interactive(self)
  return #(vim.tbl_filter(function(filter)
    return filter.is_interactive
  end, self._filters)) > 0
end

function Filters.values(self)
  return self._filters
end

function Filters.apply(self, filter_ctxs, items)
  for i, filter in ipairs(self._filters) do
    items = filter:apply(filter_ctxs:index(i), items)
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

function Filters.highlight(self, filter_ctxs, bufnr, first_line, raw_items)
  for i, filter in ipairs(self._filters) do
    if filter.highlight ~= nil then
      filter:highlight(filter_ctxs:index(i), bufnr, first_line, raw_items)
    end
  end
end

return Filters
