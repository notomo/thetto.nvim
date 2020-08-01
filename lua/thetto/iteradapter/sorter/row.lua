local M = {}

M.apply = function(items)
  table.sort(items, function(a, b)
    return a.row < b.row
  end)
  return items
end

return M
