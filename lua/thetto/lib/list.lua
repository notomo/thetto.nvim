local M = require("thetto.vendor.misclib.collection.list")

-- NOTE: keeps metatable unlike vim.fn.reverse(tbl)
function M.reverse(tbl)
  local new_tbl = {}
  for i = #tbl, 1, -1 do
    table.insert(new_tbl, tbl[i])
  end
  return new_tbl
end

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
