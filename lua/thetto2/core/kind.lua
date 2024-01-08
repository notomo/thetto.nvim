local base = require("thetto2.handler.kind.base")

local M = {}
M.__index = M

function M.by_name(kind_name, fields)
  local kind = M._by_name(kind_name, fields)
  return M._new(kind)
end

function M._by_name(kind_name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.kind." .. kind_name)
  if not origin then
    error("not found kind: " .. kind_name)
  end

  local kind = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  kind.name = kind_name
  kind._action_to_kind = kind._action_to_kind or {}

  return kind
end

function M._new(kind)
  local tbl = {
    _origin = kind,
  }
  return setmetatable(tbl, M)
end

function M.find_action(self, action_name)
  local key = self:_action_key(action_name)
  local action = self._origin[key]
  if action then
    local action_opts = self._origin.opts[action_name] or {}
    return function(items, raw_action_ctx)
      local action_ctx = vim.tbl_deep_extend("force", { opts = action_opts }, raw_action_ctx)
      return action(items, action_ctx)
    end
  end

  local err = ("not found action: kind=%s action=%s"):format(self._origin.name, action_name)
  error(err)
end

function M.action_kind_name(self, action_name)
  local key = self:_action_key(action_name)
  if rawget(self._origin, key) then
    return self._origin.name
  end
  local extend_kind_name = self._origin._action_to_kind[key]
  if extend_kind_name then
    return extend_kind_name
  end
  if base[key] then
    return "base"
  end
  return self._origin.name
end

local ACTION_PREFIX = "action_"

function M._action_key(self, action_name)
  local name = action_name
  if name == "default" then
    name = self._origin.default_action
  end
  return ACTION_PREFIX .. name
end

function M.get_preview(self, item)
  local f = self._origin.get_preview
  if not f then
    return require("thetto2.vendor.promise").resolve(), { lines = {} }
  end
  local promise, preview = f(item)
  return require("thetto2.vendor.promise").resolve(promise), preview
end

function M.can_preview(self)
  return self._origin.get_preview ~= nil
end

function M._action_name_to_kind_name_map(kind_name, kind)
  local action_name_to_kind_name = {}
  vim
    .iter(kind)
    :map(function(k)
      if not vim.startswith(k, ACTION_PREFIX) then
        return nil
      end
      return k
    end)
    :each(function(k)
      action_name_to_kind_name[k] = kind_name
    end)
  return action_name_to_kind_name
end

function M.extend(raw_kind, ...)
  local extends = vim
    .iter({ ... })
    :map(function(kind_name)
      local extend = M._by_name(kind_name)
      extend._action_to_kind = M._action_name_to_kind_name_map(kind_name, extend)
      return extend
    end)
    :totable()
  return vim.tbl_deep_extend("keep", raw_kind, unpack(extends))
end

function M.action_infos(self)
  local already = {}
  local to_action_infos = function(from, actions)
    return vim
      .iter(actions)
      :map(function(key)
        if already[key] then
          return
        end
        if not vim.startswith(key, ACTION_PREFIX) then
          return
        end
        local action_name = key:gsub("^" .. ACTION_PREFIX, "")
        already[key] = true
        return {
          from = from,
          name = action_name,
        }
      end)
      :totable()
  end

  local action_infos = {}
  vim.list_extend(action_infos, to_action_infos(self._origin.name, self._origin))
  vim.list_extend(action_infos, to_action_infos("base", base))
  return action_infos
end

return M
