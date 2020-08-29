local kinds = require "thetto/core/kind"

local M = {}

local Executor = {}
Executor.__index = Executor

function Executor.add(self, action_name, kind_name, items)
  local action, err = self:_action(action_name, kind_name, items)
  if err ~= nil then
    return err
  end
  table.insert(self.actions, action)
end

function Executor._action(self, action_name, kind_name, items)
  local kind, err = kinds.create(self, kind_name)
  if err ~= nil then
    return nil, err
  end

  local action, action_err = kind:find_action(action_name)
  if action_err ~= nil then
    return nil, action_err
  end

  return function()
    if action.behavior.quit then
      self.ctx.ui:close()
    end
    return action:execute(items, self.ctx)
  end, nil
end

function Executor.batch(self)
  local result
  for _, action in ipairs(self.actions) do
    local r, err = action()
    if err ~= nil then
      return nil, err
    end
    result = r
  end
  return result, nil
end

function Executor.action(self, action_name, kind_name, items)
  local action, err = self:_action(action_name, kind_name, items)
  if err ~= nil then
    return nil, err
  end
  return action()
end

M.create = function(ctx, source_name, action_opts, default_action)
  local executor = {
    ctx = ctx,
    source_name = source_name,
    action_opts = vim.tbl_extend("force", ctx.action_opts, action_opts),
    default_action = default_action,
    actions = {},
  }
  return setmetatable(executor, Executor)
end

return M
