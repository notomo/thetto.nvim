local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local modulelib = require("thetto.lib.module")
local vim = vim

local Filter = {}

function Filter.new(name, inversed, key, modifier)
  vim.validate({
    name = { name, "string" },
    inversed = { inversed, "boolean" },
    key = { key, "string", true },
    modifier = { modifier, "table" },
  })

  local origin = modulelib.find("thetto.handler.filter." .. name)
  if origin == nil then
    return nil, "not found filter: " .. name
  end

  local _key = key or origin.key or "value"
  if key ~= "" and modifier.name ~= nil then
    key = ("%s:%s"):format(key, modifier.name)
  else
    key = _key
  end

  local tbl = {
    inversed = inversed,
    short_name = name,
    _origin = origin,
    key = key,
    _key = _key,
    is_interactive = name == "interactive",
    _modifier = modifier,
    highlights = HighlighterFactory.new("thetto-list-highlight"),
  }

  return setmetatable(tbl, Filter)
end

function Filter.parse(name, modifier_factory)
  local inversed = false
  if vim.startswith(name, "-") then
    inversed = true
    name = name:sub(2)
  end

  local args = vim.split(name, ":", true)
  name = args[1]
  local key = args[2]

  local mod_name = args[3]
  local modifier, err = modifier_factory:create(mod_name)
  if err ~= nil then
    return nil, err
  end

  return Filter.new(name, inversed, key, modifier), nil
end

function Filter.to_value(self, item)
  return self._modifier.f(item[self._key])
end

function Filter.inverse(self)
  return Filter.new(self.short_name, not self.inversed, self._key, self._modifier)
end

function Filter.__eq(self, filter)
  return self.short_name == filter.short_name and self.inversed == filter.inversed and self.key == filter.key
end

function Filter._name(self)
  local name = ("%s:%s"):format(self.short_name, self._key)
  if self.inversed then
    name = "-" .. name
  end
  if self._modifier.name ~= nil then
    name = ("%s:%s"):format(name, self._modifier.name)
  end
  return name
end

function Filter.__index(self, k)
  if k == "name" then
    return Filter._name(self)
  end
  return rawget(Filter, k) or self._origin[k]
end

return Filter
