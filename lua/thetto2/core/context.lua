local M = {}
M.__index = function(tbl, k)
  local v = rawget(tbl._fields, k)
  if v then
    return v
  end
  return rawget(M, k)
end

local _ctxs = {}
local _ctx_map = {}

function M.set(ctx_key, fields)
  local tbl = {
    _key = ctx_key,
    _fields = {},
  }
  local ctx = setmetatable(tbl, M)
  ctx:update(fields)

  table.insert(_ctxs, 1, ctx)
  _ctx_map[ctx_key] = ctx

  return ctx
end

function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = vim.api.nvim_buf_get_name(bufnr)
  local ctx_key = path:match("^thetto://(.+)/")
  if not ctx_key then
    return nil, "not found state in: " .. path
  end

  local ctx = _ctx_map[ctx_key]
  if not ctx then
    return nil, "context is expired: " .. path
  end

  return ctx, nil
end

function M.update(self, fields)
  self._fields = vim.tbl_extend("force", self._fields, fields)
end

function M.new_key()
  return tostring(vim.uv.hrtime())
end

return M
