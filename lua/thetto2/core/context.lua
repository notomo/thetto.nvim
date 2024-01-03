--- @class ThettoContext
--- @field collector ThettoCollector
--- @field consumer ThettoConsumer
--- @field _fields table
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

  M._expire_old()
  _ctx_map[ctx_key] = ctx
  table.insert(_ctxs, 1, ctx)

  return ctx
end

local max_count = 10
function M._expire_old()
  local old_ctxs = vim.list_slice(_ctxs, max_count + 1)
  for _, ctx in ipairs(old_ctxs) do
    _ctx_map[ctx._key] = nil
    vim.api.nvim_exec_autocmds("User", {
      pattern = "thetto_ctx_deleted_" .. ctx._key,
      modeline = false,
    })
  end
  _ctxs = vim.list_slice(_ctxs, 1, max_count)
end

--- @return ThettoContext|string
function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = vim.api.nvim_buf_get_name(bufnr)
  local ctx_key = path:match("^thetto://([^/]+)/")
  if not ctx_key then
    return "not found state in: " .. path
  end

  local ctx = _ctx_map[ctx_key]
  if not ctx then
    return "context is expired: " .. path
  end

  return ctx
end

--- @return ThettoContext?
function M.resume()
  -- TODO
  local ctx = _ctxs[1]
  return ctx
end

function M.update(self, fields)
  self._fields = vim.tbl_extend("force", self._fields, fields)
end

function M.new_key()
  return tostring(vim.uv.hrtime())
end

return M
