local M = {}

M.apply = function(self, items)
  if self.reversed then
    table.sort(items, function(a, b)
      return #a.value > #b.value
    end)
  else
    table.sort(items, function(a, b)
      return #a.value < #b.value
    end)
  end
  return items
end

return M
