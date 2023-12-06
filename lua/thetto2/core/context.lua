local M = {}
M.__index = function(tbl, k)
  local v = rawget(tbl._fields, k)
  if v then
    return v
  end
  return rawget(M, k)
end

local _ctxs = {}

function M.new(fields)
  local tbl = {
    _fields = {},
  }
  local ctx = setmetatable(tbl, M)
  ctx:update(fields)

  table.insert(_ctxs, 1, ctx)

  return ctx
end

function M.get(bufnr)
  return nil
end

function M.update(self, fields)
  self._fields = vim.tbl_extend("force", self._fields, fields)
end

return M
