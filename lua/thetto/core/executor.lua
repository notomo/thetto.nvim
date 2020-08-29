local kinds = require "thetto/core/kind"

local M = {}

local Executor = {}
Executor.__index = Executor

function Executor.add(self, kind_name, items)
  local kind, err = kinds.create(self.source_name, kind_name)
  if err ~= nil then
    return err
  end

  local action, action_err = kind:find_action(self.action_opts, self.action_name, self.default_action)
  if action_err ~= nil then
    return action_err
  end

  table.insert(self.actions, function()
    if action.behavior.quit then
      self.ctx.ui:close()
    end
    return action:execute(items, self.ctx)
  end)
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

M.create = function(ctx, source_name, action_name, action_opts, default_action)
  local executor = {
    ctx = ctx,
    source_name = source_name,
    action_name = action_name,
    action_opts = vim.tbl_extend("force", ctx.action_opts, action_opts),
    default_action = default_action,
    actions = {},
  }
  return setmetatable(executor, Executor)
end

return M
