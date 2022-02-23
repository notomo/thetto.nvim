local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local modulelib = require("thetto.lib.module")
local pathlib = require("thetto.lib.path")
local vim = vim

local Modifier = {}
Modifier.__index = Modifier

local modifiers = {
  relative = function(value, opts)
    return pathlib.to_relative(value, opts.cwd)
  end,
}

function Modifier.new(name)
  local f = function(value, _)
    return value
  end
  if name ~= nil then
    f = modifiers[name]
    if f == nil then
      return nil, "not found filter modifier: " .. name
    end
  end
  local tbl = { f = f, name = name }
  return setmetatable(tbl, Modifier)
end

local Filter = {}

function Filter.new(name, opts, inversed, key, modifier)
  vim.validate({
    name = { name, "string" },
    opts = { opts, "table" },
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
    _opts = opts,
    _origin = origin,
    key = key,
    _key = _key,
    is_interactive = name == "interactive",
    modifier = modifier,
    highlights = HighlighterFactory.new("thetto-list-highlight"),
  }

  return setmetatable(tbl, Filter)
end

function Filter.parse(name, opts)
  local inversed = false
  if vim.startswith(name, "-") then
    inversed = true
    name = name:sub(2)
  end

  local args = vim.split(name, ":", true)
  name = args[1]
  local key = args[2]

  local mod_name = args[3]
  local modifier, err = Modifier.new(mod_name)
  if err ~= nil then
    return nil, err
  end

  return Filter.new(name, opts, inversed, key, modifier), nil
end

function Filter.to_value(self, item)
  return self.modifier.f(item[self._key], self._opts)
end

function Filter.inverse(self)
  return Filter.new(self.short_name, self._opts, not self.inversed, self._key, self.modifier)
end

function Filter.__eq(self, filter)
  return self.short_name == filter.short_name and self.inversed == filter.inversed and self.key == filter.key
end

function Filter._name(self)
  local name = ("%s:%s"):format(self.short_name, self._key)
  if self.inversed then
    name = "-" .. name
  end
  if self.modifier.name ~= nil then
    name = ("%s:%s"):format(name, self.modifier.name)
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
