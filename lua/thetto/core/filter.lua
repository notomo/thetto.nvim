local highlights = require("thetto/lib/highlight")
local modulelib = require("thetto/lib/module")
local pathlib = require("thetto/lib/path")

local M = {}

local modifiers = {
  relative = function(value, opts)
    return pathlib.to_relative(value, opts.cwd)
  end,
}

M.create = function(filter_name, opts)
  local inverse = false
  if vim.startswith(filter_name, "-") then
    inverse = true
    filter_name = filter_name:sub(2)
  end

  local args = vim.split(filter_name, ":", true)
  filter_name = args[1]
  local key = args[2]
  local modifier_name = args[3]
  local modifier = modifiers[modifier_name]
  if modifier_name ~= nil and modifier == nil then
    return nil, "not found filter modifier: " .. modifier_name
  end

  local origin = modulelib.find_filter(filter_name)
  if origin == nil then
    return nil, "not found filter: " .. filter_name
  end

  local filter = {}
  filter._key = key or origin.key or "value"
  if key ~= "" and modifier ~= nil then
    filter.key = ("%s:%s"):format(key, modifier_name)
  else
    filter.key = filter._key
  end
  filter.inverse = inverse
  filter.is_interactive = filter_name == "interactive"

  filter._name = function(self)
    local name = ("%s:%s"):format(filter_name, self.key)
    if self.inverse then
      name = "-" .. name
    end
    if modifier_name ~= nil then
      name = ("%s:%s"):format(name, modifier_name)
    end
    return name
  end

  filter.highlights = highlights.new_factory("thetto-filter-highlight-" .. filter:_name())

  if modifier ~= nil then
    filter.to_value = function(self, item)
      return modifier(item[self._key], opts)
    end
  else
    filter.to_value = function(self, item)
      return item[self._key]
    end
  end

  local meta = {
    __index = function(_, k)
      if k == "name" then
        return filter:_name()
      end
      return origin[k]
    end,
  }

  return setmetatable(filter, meta), nil
end

return M
