local M = {}

local ACTION_PREFIX = "action_"
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
  return vim.tbl_extend("keep", kind._action_name_to_kind_name or {}, action_name_to_kind_name)
end

local base = require("thetto.handler.kind.base")
base._action_name_to_kind_name = M._action_name_to_kind_name_map("base", base)

local _registered = {}

local default_opts = {
  use_registered = true,
}
function M.by_name(kind_name, fields, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts or {})

  local registered = _registered[kind_name]
  if opts.use_registered and registered then
    if type(registered) == "function" then
      registered = registered()
    end
    return vim.tbl_deep_extend("force", base, vim.deepcopy(registered), fields or {})
  end

  local origin = require("thetto.vendor.misclib.module").find("thetto.handler.kind." .. kind_name)
  if not origin then
    error("not found kind: " .. kind_name)
  end

  local kind = vim.tbl_deep_extend("force", base, vim.deepcopy(origin), fields or {})
  kind.name = kind_name
  kind._action_name_to_kind_name = kind._action_name_to_kind_name or {}

  return kind
end

function M.register(kind_name, kind)
  _registered[kind_name] = kind
end

local action_key = function(kind, raw_action_name)
  local action_name
  if raw_action_name == "default" then
    action_name = kind.default_action
  else
    action_name = raw_action_name
  end
  return ACTION_PREFIX .. action_name, action_name
end

function M.find_action(kind, raw_action_name)
  local key, action_name = action_key(kind, raw_action_name)
  local action = kind[key]
  if not action then
    return nil
  end

  local action_opts = kind.opts[action_name] or {}
  return function(items, raw_action_ctx)
    local action_ctx = vim.tbl_deep_extend("force", { opts = action_opts }, raw_action_ctx)
    return action(items, action_ctx)
  end
end

function M.action_kind_name(kind, action_name)
  local key = action_key(kind, action_name)

  local extend_kind_name = kind._action_name_to_kind_name[key]
  if extend_kind_name then
    return extend_kind_name
  end

  return kind.name
end

function M.get_preview(kind, item, raw_action_ctx)
  local f = kind.get_preview
  if not f then
    return require("thetto.vendor.promise").resolve(), { lines = {} }
  end

  local action_opts = vim.tbl_get(kind, "opts", "preview") or {}
  local action_ctx = vim.tbl_deep_extend("force", { opts = action_opts }, raw_action_ctx or {})
  local promise, preview = f(item, action_ctx)
  return require("thetto.vendor.promise").resolve(promise), preview or { lines = {} }
end

function M.can_preview(kind)
  return kind.get_preview ~= nil
end

function M.extend(kind, ...)
  local extends = vim
    .iter({ ... })
    :map(function(kind_name)
      local extend = M.by_name(kind_name)
      extend._action_name_to_kind_name = M._action_name_to_kind_name_map(kind_name, extend)
      return extend
    end)
    :totable()
  local extended = vim.tbl_deep_extend("keep", kind, unpack(extends))
  return extended
end

function M.action_infos(kind)
  local already = {}
  return vim
    .iter(kind)
    :map(function(key)
      if already[key] then
        return
      end

      if not vim.startswith(key, ACTION_PREFIX) then
        return
      end
      already[key] = true

      local action_name = key:gsub("^" .. ACTION_PREFIX, "")
      return {
        from = M.action_kind_name(kind, action_name),
        name = action_name,
      }
    end)
    :totable()
end

function M.registered_names()
  return vim.iter(vim.tbl_keys(_registered)):totable()
end

function M.setup(kinds)
  _registered = vim.tbl_extend("force", _registered, kinds or {})
end

return M
