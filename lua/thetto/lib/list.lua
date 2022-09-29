local M = require("thetto.vendor.misclib.collection.list")

function M.remove(list, value)
  local idx
  for i, v in ipairs(list) do
    if v == value then
      idx = i
      break
    end
  end

  if idx ~= nil then
    table.remove(list, idx)
    return true
  end
  return false
end

return M
