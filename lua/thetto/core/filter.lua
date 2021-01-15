local highlights = require("thetto/lib/highlight")
local modulelib = require("thetto/lib/module")
local pathlib = require("thetto/lib/path")

local M = {}

local FilterModifier = {}
FilterModifier.__index = FilterModifier

local modifiers = {
  relative = function(value, opts)
    return pathlib.to_relative(value, opts.cwd)
  end,
}

function FilterModifier.new(name)
  local f = function(value, _)
    return value
  end
  if name ~= nil then
    f = modifiers[name]
    if f == nil then
      return nil, "not found filter modifier: " .. name
    end
  end
  local tbl = {f = f, name = name}
  return setmetatable(tbl, FilterModifier)
end

local Filter = {}
Filter.__index = Filter
M.Filter = Filter

function Filter.new(name, opts, inversed, key, modifier)
  vim.validate({
    name = {name, "string"},
    opts = {opts, "table"},
    inversed = {inversed, "boolean"},
    key = {key, "string", true},
    modifier = {modifier, "table"},
  })

  local origin = modulelib.find_filter(name)
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
  }
  tbl.highlights = highlights.new_factory("thetto-filter-highlight-" .. Filter._name(tbl))

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
  local modifier, err = FilterModifier.new(mod_name)
  if err ~= nil then
    return nil, err
  end

  return Filter.new(name, opts, inversed, key, modifier), nil
end

function Filter.to_value(self, item)
  return self.modifier.f(item[self._key], self._opts)
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

return M
