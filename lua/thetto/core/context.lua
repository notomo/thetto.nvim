--- @class ThettoContext
--- @field collector ThettoCollector
--- @field consumer ThettoConsumer
--- @field private _fields table
local M = {}
M.__index = function(tbl, k)
  local v = rawget(tbl._fields, k)
  if v then
    return v
  end
  return rawget(M, k)
end

local now = function()
  return vim.uv.hrtime()
end

local _ctx_map = {}

function M.set(ctx_key, fields)
  local tbl = {
    _key = ctx_key,
    _used_at = now(),
    _fields = {},
  }
  local ctx = setmetatable(tbl, M)
  ctx:update(fields)

  M._expire_old()
  _ctx_map[ctx_key] = ctx

  return ctx
end

local make_pattern = function(ctx_key)
  return "thetto_ctx_deleted_" .. ctx_key
end

local _group = vim.api.nvim_create_augroup("thetto_ctx", {})

function M.setup_expire(ctx_key, f)
  vim.api.nvim_create_autocmd({ "User" }, {
    group = _group,
    pattern = { make_pattern(ctx_key) },
    callback = f,
    once = true,
  })
end

local max_count = 10
function M._expire_old()
  local ctxs = vim
    .iter(_ctx_map)
    :map(function(_, v)
      return v
    end)
    :totable()
  table.sort(ctxs, function(a, b)
    return a._used_at > b._used_at
  end)

  local old_ctxs = vim.list_slice(ctxs, max_count + 1)
  for _, ctx in ipairs(old_ctxs) do
    _ctx_map[ctx._key] = nil
    vim.api.nvim_exec_autocmds("User", {
      pattern = make_pattern(ctx._key),
      modeline = false,
    })
  end
end

--- @return ThettoContext|string
function M.get(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "invalid buffer: " .. tostring(bufnr)
  end

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
--- @return ThettoContext?
function M.resume(offset)
  local ctxs = vim
    .iter(_ctx_map)
    :map(function(_, v)
      return v
    end)
    :totable()
  table.sort(ctxs, function(a, b)
    return a._used_at > b._used_at
  end)

  if #ctxs == 0 then
    return nil
  end

  if offset == 0 then
    local ctx = ctxs[1]
    ctx._used_at = now()
    return ctx
  end

  local current = M.get()
  if type(current) == "string" then
    return
  end

  local index = 1
  for i, ctx in ipairs(ctxs) do
    if ctx._key == current._key then
      index = i
      break
    end
  end
  local wrapped_index = (index + offset) % #ctxs
  if wrapped_index == 0 then
    wrapped_index = #ctxs
  end

  local ctx = ctxs[wrapped_index]
  ctx._used_at = now()
  return ctx, current
end

function M.update(self, fields)
  self._fields = vim.tbl_extend("force", self._fields, fields)
end

function M.new_key()
  return tostring(now())
end

return M
