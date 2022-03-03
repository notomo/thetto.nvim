local M = {}

function M.apply(self, _, items)
  return require("thetto.lib.list").unique(items, function(item)
    return self:to_value(item) or ""
  end)
end

return M
