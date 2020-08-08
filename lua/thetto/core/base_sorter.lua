local modulelib = require("thetto/lib/module")

local M = {}

M.create = function(sorter_name)
  local reverse = false
  if vim.startswith(sorter_name, "-") then
    reverse = true
    sorter_name = sorter_name:sub(2)
  end

  local origin = modulelib.find_iteradapter("sorter/" .. sorter_name)
  if origin == nil then
    return nil, "not found sorter: " .. sorter_name
  end
  origin.__index = origin

  local sorter = {}
  sorter.reverse = reverse

  sorter.get_name = function(self)
    local name = sorter_name
    if self.reverse then
      name = "-" .. name
    end
    return name
  end
  sorter.name = sorter:get_name()

  return setmetatable(sorter, origin), nil
end

return M
