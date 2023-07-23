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

  local opts = vim.deepcopy(origin.opts or {})
  local behaviors = vim.deepcopy(origin.behaviors or {})
  for _, extend in ipairs(origin.extends or {}) do
    opts = vim.tbl_deep_extend("keep", opts, extend.opts or {})
    behaviors = vim.tbl_deep_extend("keep", behaviors, extend.behaviors or {})
  end

  local tbl = {
    name = name,
    executor = executor,
    default_action = kind_actions.default_action or executor.default_action_name,
    opts = vim.tbl_deep_extend("force", base.opts, opts, user_opts, execute_opts.source_actions.opts),
    behaviors = vim.tbl_deep_extend(
      "force",
      base.behaviors,
      behaviors,
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

function Kind.will_skip_action(self, action_name)
  return vim.tbl_get(self.behaviors, action_name, "skip") or false
end

function Kind.action_kind_name(self, action_name)
  local key = self:_action_key(action_name)
  if rawget(self._origin, key) then
    return self.name
  end
  for _, extend in ipairs(self._origin.extends or {}) do
    if extend[key] then
      return extend.name
    end
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

Kind.ErrNotFoundAction = "not found action: "

function Kind.find_action(self, action_name, action_opts)
  local key, name = self:_action_key(action_name)
  local opts = vim.tbl_extend("force", self.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", { quit = true }, self.behaviors[name] or {})

  local source_actions = self._execute_opts.source_actions
  if source_actions[key] then
    return Action.new(self.name, source_actions[key], opts, behavior), nil
  end

  local kind_action = self._execute_opts.kind_actions[self.name]
  if kind_action ~= nil and kind_action[key] then
    return Action.new(self.name, kind_action[key], opts, behavior), nil
  end

  for _, extend in ipairs(self._origin.extends or {}) do
    local action = self._execute_opts.kind_actions[extend.name]
    if action ~= nil and action[key] then
      return Action.new(self.name, action[key], opts, behavior), nil
    end
  end

  local action = self[key]
  if action ~= nil then
    return Action.new(self.name, action, opts, behavior), nil
  end

  return nil, Kind.ErrNotFoundAction .. name
end

function Kind.action_infos(self)
  local already = {}
  local to_action_infos = function(from, actions)
    return vim
      .iter(actions)
      :map(function(key)
        if already[key] then
          return
        end
        if not vim.startswith(key, Action.PREFIX) then
          return
        end
        local action_name = key:gsub("^" .. Action.PREFIX, "")
        already[key] = true
        return {
          from = from,
          name = action_name,
        }
      end)
      :totable()
  end

  local action_infos = {}

  vim.list_extend(action_infos, to_action_infos("source_actions option", self._execute_opts.source_actions))
  vim.list_extend(
    action_infos,
    to_action_infos("kind_actions option", self._execute_opts.kind_actions[self.name] or {})
  )
  vim.list_extend(action_infos, to_action_infos(self.name, self._origin))
  for _, extend in ipairs(self._origin.extends or {}) do
    vim.list_extend(action_infos, to_action_infos(extend.name, getmetatable(extend)))
  end
  vim.list_extend(action_infos, to_action_infos("base", base))

  return action_infos
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
    local kind_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/handler/kind/", { plain = true })[2]
    local name = kind_file:sub(1, #kind_file - 4)
    local ignored = vim.startswith(vim.fs.basename(kind_file), "_")
    if not ignored and not already[name] then
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
