local Sorter = require("thetto.core.items.sorter")
local vim = vim

local Sorters = {}

function Sorters.new(names, reversed)
  local sorters = {}
  for _, name in ipairs(names) do
    local sorter, err = Sorter.parse(name)
    if err ~= nil then
      return nil, err
    end
    table.insert(sorters, sorter)
  end

  local tbl = {
    _sorters = sorters,
    _reversed = reversed or false,
  }
  return setmetatable(tbl, Sorters)
end

function Sorters.__index(self, k)
  if type(k) == "number" then
    return self._sorters[k]
  end
  return Sorters[k]
end

local DISABLED_SORTER_ERR = "sorter is disabled: "

function Sorters._find(self, name)
  for i, sorter in ipairs(self._sorters) do
    if sorter.short_name == name then
      return sorter, i, nil
    end
  end
  return nil, nil, DISABLED_SORTER_ERR .. name
end

function Sorters._names(self)
  return vim.tbl_map(function(sorter)
    return sorter.name
  end, self._sorters)
end

function Sorters.reverse_one(self, name)
  local sorter, index, err = self:_find(name)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  names[index] = sorter:reverse().name
  return Sorters.new(names), nil
end

function Sorters.reverse(self)
  local names = self:_names()
  return Sorters.new(names, not self._reversed), nil
end

function Sorters.toggle(self, name)
  if name == nil then
    return nil, "need sorter name"
  end

  local sorter, index, err = self:_find(name)
  if err ~= nil and not vim.startswith(err, DISABLED_SORTER_ERR) then
    return nil, err
  end

  if sorter ~= nil then
    local names = self:_names()
    table.remove(names, index)
    return Sorters.new(names), nil
  end

  sorter, err = Sorter.parse(name)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  table.insert(names, sorter.name)
  return Sorters.new(names), nil
end

function Sorters.length(self)
  return #self._sorters
end

function Sorters.values(self)
  return self._sorters
end

local reverse = require("thetto.lib.list").reverse
local apply_reverse = function(items, reversed)
  if not reversed then
    return items
  end
  return reverse(items)
end

function Sorters.apply(self, items)
  if #self._sorters == 0 then
    return apply_reverse(items, self._reversed)
  end

  local compare = function(item_a, item_b)
    for _, sorter in ipairs(self._sorters) do
      local a = sorter:value(item_a)
      local b = sorter:value(item_b)
      if a ~= b then
        return (a > b and sorter.reversed) or not (a > b or sorter.reversed)
      end
    end
    return false
  end

  table.sort(items, compare)

  return apply_reverse(items, self._reversed)
end

return Sorters
