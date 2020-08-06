local highlights = require("thetto/view/highlight")
local modulelib = require("thetto/lib/module")

local M = {}

M.create = function(filter_name)
  local inverse = false
  if vim.startswith(filter_name, "-") then
    inverse = true
    filter_name = filter_name:sub(2)
  end

  local origin = modulelib.find_iteradapter("filter/" .. filter_name)
  if origin == nil then
    return nil, "not found filter: " .. filter_name
  end
  origin.__index = origin

  local filter = {}
  filter.name = filter_name
  filter.inverse = inverse
  filter.highlights = highlights

  return setmetatable(filter, origin), nil
end

return M
