local modulelib = require("thetto/lib/module")

local M = {}

M.create = function(sorter_name)
  local reverse = false
  if vim.startswith(sorter_name, "-") then
    reverse = true
    sorter_name = sorter_name:sub(2)
  end

  local origin = modulelib.find_sorter(sorter_name)
  if origin == nil then
    return nil, "not found sorter: " .. sorter_name
  end

  local sorter = {}
  sorter.reverse = reverse
  sorter._name = function(self)
    local name = sorter_name
    if self.reverse then
      name = "-" .. name
    end
    return name
  end

  local meta = {
    __index = function(_, k)
      if k == "name" then
        return sorter:_name()
      end
      return origin[k]
    end,
  }

  return setmetatable(sorter, meta), nil
end

return M
