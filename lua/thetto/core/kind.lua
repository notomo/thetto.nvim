local jobs = require("thetto/lib/job")
local modulelib = require("thetto/lib/module")
local filelib = require("thetto/lib/file")
local custom = require("thetto/custom")
local base = require("thetto/kind/base")
local vim = vim

local M = {}

local Action = {}
Action.PREFIX = "action_"

function Action.new(kind, fn, action_opts, behavior)
  local tbl = {action_opts = action_opts, behavior = behavior, _kind = kind, _fn = fn}
  return setmetatable(tbl, Action)
end

function Action.execute(self, items, ctx)
  return self:_fn(items, ctx)
end

function Action.__index(self, k)
  return rawget(Action, k) or self._kind[k]
end

local Kind = {}
M.Kind = Kind

Kind.jobs = jobs
Kind.filelib = filelib

function Kind.new(executor, name)
  local origin = modulelib.find_kind(name)
  if origin == nil then
    return nil, "not found kind: " .. name
  end

  local source_name = executor.source_name
  local source_user_opts = {}
  local source_user_behaviors = {}
  if custom.source_actions ~= nil and custom.source_actions[source_name] ~= nil then
    source_user_opts = custom.source_actions[source_name].opts or {}
    source_user_behaviors = custom.source_actions[source_name].behaviors or {}
  end

  local user_opts = {}
  local user_behaviors = {}
  if custom.kind_actions ~= nil and custom.kind_actions[name] ~= nil then
    user_opts = custom.kind_actions[name].opts or {}
    user_behaviors = custom.kind_actions[name].behaviors or {}
  end

  local tbl = {
    name = name,
    executor = executor,
    source_name = source_name,
    opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}, user_opts, source_user_opts),
    behaviors = vim.tbl_deep_extend("force", base.behaviors, origin.behaviors or {}, user_behaviors, source_user_behaviors),
    _origin = origin,
  }
  tbl.__index = tbl
  return setmetatable(tbl, Kind)
end

function Kind.__index(self, k)
  return rawget(Kind, k) or self._origin[k] or base[k]
end

function Kind.find_action(self, action_name, action_opts)
  local name = action_name
  if name == "default" then
    name = self.default_action
  end

  local key = Action.PREFIX .. name
  local opts = vim.tbl_extend("force", self.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", {quit = true}, self.behaviors[name] or {})

  local source_action = custom.source_actions[self.source_name]
  if source_action ~= nil and source_action[key] then
    return Action.new(self, source_action[key], opts, behavior), nil
  end

  local kind_action = custom.kind_actions[self.name]
  if kind_action ~= nil and kind_action[key] then
    return Action.new(self, kind_action[key], opts, behavior), nil
  end

  local action = self[key]
  if action ~= nil then
    return Action.new(self, action, opts, behavior), nil
  end

  return nil, "not found action: " .. name
end

function Kind.actions(self)
  local names = {}
  local actions = vim.tbl_extend("force", self._origin, base, custom.source_actions[self.source_name] or {}, custom.kind_actions[self.name] or {})
  for key in pairs(actions) do
    if vim.startswith(key, Action.PREFIX) then
      local action_name = key:gsub("^" .. Action.PREFIX, "")
      table.insert(names, action_name)
    end
  end
  return names
end

return M
