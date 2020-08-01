local M = {}

M.apply = function(items)
  table.sort(items, function(a, b)
    return #a.value < #b.value
  end)
  return items
end

return M
