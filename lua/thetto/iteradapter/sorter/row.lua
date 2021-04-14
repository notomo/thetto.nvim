local M = {}

function M.apply(self, items)
  if self.reversed then
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
