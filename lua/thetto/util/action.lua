local M = {}

function M.call(kind_name, action_name, items, ctx, action_opts)
  local kind, kind_err = require("thetto.core.kind").new(ctx.executor, kind_name)
  if kind_err then
    return nil, kind_err
  end

  local action, action_err = kind:find_action(action_name, action_opts or {})
  if action_err then
    return nil, action_err
  end

  return action:execute(items, ctx)
end

return M
