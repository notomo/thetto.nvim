local pathlib = require("thetto.lib.path")
local modulelib = require("thetto.vendor.misclib.module")
local base = require("thetto.handler.kind.base")
local vim = vim
local Action = require("thetto.core.action")

local Kind = {}

function Kind.new(executor, name)
  vim.validate({ executor = { executor, "table" }, name = { name, "string" } })

  local origin, err = Kind._find(name)
  if err then
    return nil, err
  end

  local execute_opts = executor.execute_opts

  local kind_actions = execute_opts.kind_actions[name] or {}
  local user_opts = kind_actions.opts or {}
  local user_behaviors = kind_actions.behaviors or {}

  local tbl = {
    name = name,
    executor = executor,
    default_action = kind_actions.default_action or executor.default_action_name,
    opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}, user_opts, execute_opts.source_actions.opts),
    behaviors = vim.tbl_deep_extend(
      "force",
      base.behaviors,
      origin.behaviors or {},
      user_behaviors,
      execute_opts.source_actions.behaviors
    ),
    _execute_opts = executor.execute_opts,
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
  local key, name = self:_action_key(action_name)
  local opts = vim.tbl_extend("force", self.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", { quit = true }, self.behaviors[name] or {})

  local source_actions = self._execute_opts.source_actions
  if source_actions[key] then
    return Action.new(source_actions[key], opts, behavior), nil
  end

  local kind_action = self._execute_opts.kind_actions[self.name]
  if kind_action ~= nil and kind_action[key] then
    return Action.new(kind_action[key], opts, behavior), nil
  end

  for _, extend in ipairs(self._origin.extends or {}) do
    local action = self._execute_opts.kind_actions[extend.name]
    if action ~= nil and action[key] then
      return Action.new(action[key], opts, behavior), nil
    end
  end

  local action = self[key]
  if action ~= nil then
    return Action.new(action, opts, behavior), nil
  end

  return nil, "not found action: " .. name
end

function Kind.action_names(self)
  local names = {}

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
    self._execute_opts.source_actions,
    self._execute_opts.kind_actions[self.name] or {}
  )
  for key in pairs(actions) do
    if vim.startswith(key, Action.PREFIX) then
      local action_name = key:gsub("^" .. Action.PREFIX, "")
      table.insert(names, action_name)
    end
  end
  return names
end

function Kind._find(name)
  local origin = modulelib.find("thetto.handler.kind." .. name)
  if origin == nil then
    return nil, "not found kind: " .. name
  end
  return origin, nil
end

function Kind.extend(raw_kind, ...)
  local extend_names = { ... }
  local extends = {}
  for _, name in ipairs(extend_names) do
    local extend, err = Kind._find(name)
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

function Kind.all()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/kind/**/*.lua", true)
  local already = {}
  local all = {}
  for _, path in ipairs(paths) do
    local kind_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/handler/kind/", true)[2]
    local name = kind_file:sub(1, #kind_file - 4)
    if not already[name] then
      local kind_info = {
        name = name,
        path = path,
      }
      table.insert(all, kind_info)
      already[name] = kind_info
    end
  end
  return all
end

return Kind
