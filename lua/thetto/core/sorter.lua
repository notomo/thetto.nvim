local modulelib = require("thetto.lib.module")
local vim = vim

local M = {}

local Sorter = {}
M.Sorter = Sorter

function Sorter.new(name, reversed)
  vim.validate({name = {name, "string"}, reversed = {reversed, "boolean"}})

  local origin = modulelib.find("thetto/handler/sorter/" .. name)
  if origin == nil then
    return nil, "not found sorter: " .. name
  end

  local tbl = {reversed = reversed, short_name = name, _origin = origin}
  return setmetatable(tbl, Sorter), nil
end

function Sorter.parse(name)
  if vim.startswith(name, "-") then
    return Sorter.new(name:sub(2), true)
  end
  return Sorter.new(name, false)
end

function Sorter.reverse(self)
  return Sorter.new(self.short_name, not self.reversed)
end

function Sorter._name(self)
  if self.reversed then
    return "-" .. self.short_name
  end
  return self.short_name
end

function Sorter.__index(self, k)
  if k == "name" then
    return Sorter._name(self)
  end
  return rawget(Sorter, k) or self._origin[k]
end

local Sorters = {}
M.Sorters = Sorters

function Sorters.new(names)
  local sorters = {}
  for _, name in ipairs(names) do
    local sorter, err = Sorter.parse(name)
    if err ~= nil then
      return nil, err
    end
    table.insert(sorters, sorter)
  end

  local tbl = {_sorters = sorters}
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

function Sorters.reverse(self, name)
  local sorter, index, err = self:_find(name)
  if err ~= nil then
    return nil, err
  end

  local names = self:_names()
  names[index] = sorter:reverse().name
  return Sorters.new(names), nil
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

function Sorters.iter(self)
  return next, self._sorters, nil
end

function Sorters.length(self)
  return #self._sorters
end

function Sorters.values(self)
  return self._sorters
end

return M
