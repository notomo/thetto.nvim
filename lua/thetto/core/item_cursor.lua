--- @alias ThettoItemCursorFactory fun(items:table[]):ThettoItemCursor

--- @class ThettoItemCursor
--- @field row number?
--- @field row_offset number?
local M = {}
M.__index = M

local default = {
  row = nil,
  row_offset = 0,
}
function M.new(raw_item_cursor)
  local tbl = vim.tbl_deep_extend("force", default, raw_item_cursor)
  return setmetatable(tbl, M)
end

function M.apply(self, row, max_row)
  row = self.row or row
  row = math.max(1, row + self.row_offset)
  row = math.min(row, max_row)
  return row
end

return M
