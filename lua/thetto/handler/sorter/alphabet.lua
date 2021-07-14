local M = {}

function M.value(_, item)
  return item.value:lower()
end

return M
