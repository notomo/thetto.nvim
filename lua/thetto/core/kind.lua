local jobs = require("thetto.lib.job")
local modulelib = require("thetto.lib.module")
local filelib = require("thetto.lib.file")
local base = require("thetto.handler.kind.base")
local vim = vim

local M = {}

local Action = {}
Action.PREFIX = "action_"

function Action.new(kind, fn, action_opts, behavior)
  local tbl = { action_opts = action_opts, behavior = behavior, _kind = kind, _fn = fn }
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
  vim.validate({ executor = { executor, "table" }, name = { name, "string" } })

  local origin, err = M._find(name)
  if err then
    return nil, err
  end

  local source_name = executor.source_name
  local source_user_opts = {}
  local source_user_behaviors = {}
  local config = require("thetto.core.custom").config
  if config.source_actions ~= nil and config.source_actions[source_name] ~= nil then
    source_user_opts = config.source_actions[source_name].opts or {}
    source_user_behaviors = config.source_actions[source_name].behaviors or {}
  end

  local user_opts = {}
  local user_behaviors = {}
  if config.kind_actions ~= nil and config.kind_actions[name] ~= nil then
    user_opts = config.kind_actions[name].opts or {}
    user_behaviors = config.kind_actions[name].behaviors or {}
  end

  local tbl = {
    name = name,
    executor = executor,
    default_action = executor.default_action_name,
    source_name = source_name,
    opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}, user_opts, source_user_opts),
    behaviors = vim.tbl_deep_extend(
      "force",
      base.behaviors,
      origin.behaviors or {},
      user_behaviors,
      source_user_behaviors
    ),
    _origin = origin,
  }
  return setmetatable(tbl, Kind)
end

function Kind.__index(self, k)
  return rawget(Kind, k) or self._origin[k] or base[k]
end

function Kind.action_kind_name(self, action_name)
  local key = self:_action_key(action_name)
  if self._origin[key] then
    return self.name
  end
  if base[key] then
    return "base"
  end
  return self.name
end

function Kind._action_key(self, action_name)
  local name = action_name
  if name == "default" then
    name = self.default_action
  end
  return Action.PREFIX .. name, name
end

function Kind.find_action(self, action_name, action_opts)
  local config = require("thetto.core.custom").config

  local key, name = self:_action_key(action_name)
  local opts = vim.tbl_extend("force", self.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", { quit = true }, self.behaviors[name] or {})

  local source_action = config.source_actions[self.source_name]
  if source_action ~= nil and source_action[key] then
    return Action.new(self, source_action[key], opts, behavior), nil
  end

  local kind_action = config.kind_actions[self.name]
  if kind_action ~= nil and kind_action[key] then
    return Action.new(self, kind_action[key], opts, behavior), nil
  end

  for _, extend in ipairs(self._origin.extends or {}) do
    local action = config.kind_actions[extend.name]
    if action ~= nil and action[key] then
      return Action.new(self, action[key], opts, behavior), nil
    end
  end

  local action = self[key]
  if action ~= nil then
    return Action.new(self, action, opts, behavior), nil
  end

  return nil, "not found action: " .. name
end

function Kind.action_names(self)
  local names = {}
  local config = require("thetto.core.custom").config

  local extends = vim.tbl_map(function(e)
    return getmetatable(e)
  end, self._origin.extends or {})
  if vim.tbl_isempty(extends) then
    extends = { {} }
  end

  local actions = vim.tbl_extend("force", self._origin, unpack(extends))
  actions = vim.tbl_extend(
    "force",
    actions,
    base,
    config.source_actions[self.source_name] or {},
    config.kind_actions[self.name] or {}
  )
  for key in pairs(actions) do
    if vim.startswith(key, Action.PREFIX) then
      local action_name = key:gsub("^" .. Action.PREFIX, "")
      table.insert(names, action_name)
    end
  end
  return names
end

function M._find(name)
  local origin = modulelib.find("thetto.handler.kind." .. name)
  if origin == nil then
    return nil, "not found kind: " .. name
  end
  return origin, nil
end

function M.extend(raw_kind, ...)
  local extend_names = { ... }
  local extends = {}
  for _, name in ipairs(extend_names) do
    local extend, err = M._find(name)
    if err then
      error(err)
    end
    extend.__index = extend
    table.insert(extends, setmetatable({ name = name }, extend))
  end
  raw_kind.extends = extends

  return setmetatable(raw_kind, {
    __index = function(_, k)
      local value = rawget(raw_kind, k)
      if value then
        return value
      end
      for _, extend in ipairs(extends) do
        local v = extend[k]
        if v then
          return v
        end
      end
    end,
  })
end

return M
