local M = {}

function M.value(self, item)
  return vim.tbl_get(item, unpack(self.keys))
end

return M
