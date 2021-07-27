local M = {}

function M.value(self, item)
  return item[self.key]
end

return M
