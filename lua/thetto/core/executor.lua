local kinds = require "thetto/core/kind"

local M = {}

local Executor = {}
Executor.__index = Executor

function Executor.add(self, action_name, kind_name, items, action_opts)
  local action, err = self:_action(action_name, kind_name, items, action_opts)
  if err ~= nil then
    return err
  end
  table.insert(self.actions, action)
end

function Executor._action(self, action_name, kind_name, items, action_opts)
  local kind, err = kinds.create(self, kind_name)
  if err ~= nil then
    return nil, err
  end

  local name
  if action_name == "default" and self.default_action_name ~= nil then
    name = self.default_action_name
  else
    name = action_name
  end

  local opts = vim.tbl_extend("force", self.default_action_opts, action_opts or {})

  local action, action_err = kind:find_action(name, opts)
  if action_err ~= nil then
    return nil, action_err
  end

  return function(ctx)
    if action.behavior.quit then
      self.notifier:send("close")
    end
    return action:execute(items, ctx)
  end, nil
end

function Executor.batch(self, ctx)
  local actions = {}
  for _, action in ipairs(self.actions) do
    table.insert(actions, action)
  end
  self.actions = {}

  local result
  for _, action in ipairs(actions) do
    local r, err = action(ctx)
    if err ~= nil then
      return nil, err
    end
    result = r
  end
  return result, nil
end

function Executor.action(self, ctx, action_name, kind_name, items, action_opts)
  local action, err = self:_action(action_name, kind_name, items, action_opts)
  if err ~= nil then
    return nil, err
  end
  return action(ctx)
end

M.create = function(notifier, source_name, default_action_opts, default_action_name)
  local executor = {
    notifier = notifier,
    source_name = source_name,
    default_action_opts = default_action_opts,
    default_action_name = default_action_name,
    actions = {},
  }
  return setmetatable(executor, Executor)
end

return M
