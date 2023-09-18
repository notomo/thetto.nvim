local M = {}

function M.value(self, item)
  local v = vim.tbl_get(item, unpack(self.keys))
  if v then
    return 1
  end
  return 0
end

return M
