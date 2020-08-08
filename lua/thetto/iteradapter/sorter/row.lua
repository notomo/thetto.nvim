local M = {}

M.apply = function(self, items)
  if self.reverse then
    table.sort(items, function(a, b)
      return a.row > b.row
    end)
  else
    table.sort(items, function(a, b)
      return a.row < b.row
    end)
  end
  return items
end

return M
