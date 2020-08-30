local jobs = require("thetto/lib/job")
local modulelib = require("thetto/lib/module")
local custom = require("thetto/custom")
local base = require("thetto/kind/base")

local M = {}

local Action = function(kind, fn, action_opts, behavior)
  local tbl = {action_opts = action_opts, behavior = behavior}
  local action = setmetatable(tbl, kind)
  action.execute = function(self, items, ctx)
    return fn(self, items, ctx)
  end
  return action
end

local action_prefix = "action_"

local find_action = function(kind, action_name, current_action_opts)
  local action_opts = vim.tbl_extend("force", kind.executor.default_action_opts, current_action_opts or {})
  local default_action_name = kind.executor.default_action

  local name
  if action_name == "default" and default_action_name ~= nil then
    name = default_action_name
  else
    name = action_name
  end
  if name == "default" then
    name = kind.default_action
  end

  local key = action_prefix .. name
  local opts = vim.tbl_extend("force", kind.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", {quit = true}, kind.behaviors[name] or {})

  local source_action = custom.source_actions[kind.source_name]
  if source_action ~= nil and source_action[key] then
    return Action(kind, source_action[key], opts, behavior), nil
  end

  local kind_action = custom.kind_actions[kind.name]
  if kind_action ~= nil and kind_action[key] then
    return Action(kind, kind_action[key], opts, behavior), nil
  end

  local action = kind[key]
  if action ~= nil then
    return Action(kind, action, opts, behavior), nil
  end

  return nil, "not found action: " .. name
end

M.create = function(executor, kind_name)
  local origin
  if kind_name == "base" then
    origin = base
  else
    local found = modulelib.find_kind(kind_name)
    if found == nil then
      return nil, "not found kind: " .. kind_name
    end
    origin = setmetatable(found, base)
    origin.__index = origin
  end

  local source_name = executor.source_name

  local kind = {}
  kind.name = kind_name
  kind.source_name = source_name
  kind.jobs = jobs
  kind.executor = executor
  kind.find_action = find_action
  kind.__index = kind

  kind.behaviors = vim.tbl_deep_extend("force", base.behaviors, origin.behaviors or {})

  local source_user_opts = {}
  if custom.source_actions ~= nil and custom.source_actions[source_name] ~= nil then
    source_user_opts = custom.source_actions[source_name].opts or {}
  end
  local user_opts = {}
  if custom.kind_actions ~= nil and custom.kind_actions[kind_name] ~= nil then
    user_opts = custom.kind_actions[kind_name].opts or {}
  end
  kind.opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}, user_opts, source_user_opts)

  return setmetatable(kind, origin), nil
end

M.actions = function(executor, kind_name)
  local kind = M.create(executor, kind_name)
  if kind == nil then
    return {}
  end

  local names = {}
  local source_name = executor.source_name
  local kinds = vim.tbl_extend("force", getmetatable(kind), base, custom.source_actions[source_name] or {}, custom.kind_actions[kind_name] or {})
  for key in pairs(kinds) do
    if vim.startswith(key, action_prefix) then
      local name = key:gsub("^" .. action_prefix, "")
      table.insert(names, name)
    end
  end

  return names
end

return M
