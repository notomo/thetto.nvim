local ActionContext = {}

function ActionContext.new(kind_name, action_opts, behavior)
  local tbl = {
    kind_name = kind_name,
    opts = action_opts,
    behavior = behavior,
  }
  return setmetatable(tbl, ActionContext)
end

local Action = {}
Action.__index = Action

Action.PREFIX = "action_"

function Action.new(kind_name, fn, action_opts, behavior)
  local action_ctx = ActionContext.new(kind_name, action_opts, behavior)
  local tbl = { _action_ctx = action_ctx, _fn = fn }
  return setmetatable(tbl, Action)
end

function Action.execute(self, items, ctx)
  if self._action_ctx.behavior.quit then
    ctx.ui:close()
  end
  return self._fn(items, self._action_ctx, ctx)
end

return Action
