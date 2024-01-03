local base = require("thetto2.handler.kind.base")

local M = {}
M.__index = M

function M.new(kind_name)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.kind." .. kind_name)
  if not origin then
    error("not found kind: " .. kind_name)
  end

  local kind = vim.deepcopy(origin)
  kind.name = kind_name

  local tbl = {
    _kind = kind,
  }
  return setmetatable(tbl, M)
end

function M.find_action(self, action_name)
  local key = self:_action_key(action_name)
  local action = self._kind[key]
  if action then
    return action
  end

  local err = ("not found action: kind=%s action=%s"):format(self._kind.name, action_name)
  error(err)
end

function M.action_kind_name(self, action_name)
  local key = self:_action_key(action_name)
  if rawget(self._kind, key) then
    return self._kind.name
  end
  if base[key] then
    return "base"
  end
  return self._kind.name
end

function M._action_key(self, action_name)
  local name = action_name
  if name == "default" then
    name = self._kind.default_action
  end
  return "action_" .. name, name
end

function M.get_preview(self, item)
  local f = self._kind.get_preview
  if not f then
    return require("thetto2.vendor.promise").resolve(), { lines = {} }
  end
  local promise, preview = f(item)
  return require("thetto2.vendor.promise").resolve(promise), preview
end

return M
