local highlights = require("thetto/view/highlight")
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

  local origin = modulelib.find_iteradapter("filter/" .. filter_name)
  if origin == nil then
    return nil, "not found filter: " .. filter_name
  end
  origin.__index = origin

  local filter = {}
  filter.key = key or origin.key or "value"
  filter.inverse = inverse
  filter.highlights = highlights

  filter.get_name = function(self)
    local name = ("%s:%s"):format(filter_name, self.key)
    if self.inverse then
      name = "-" .. name
    end
    if modifier_name ~= nil then
      name = ("%s:%s"):format(name, modifier_name)
    end
    return name
  end
  filter.name = filter:get_name()

  if modifier ~= nil then
    filter.to_value = function(self, item)
      return modifier(item[self.key], opts)
    end
  else
    filter.to_value = function(self, item)
      return item[self.key]
    end
  end

  return setmetatable(filter, origin), nil
end

return M