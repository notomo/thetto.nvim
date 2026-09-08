local M = {}

--- @async
function M.execute(action_item_groups, action_opts)
  local result
  for _, group in ipairs(action_item_groups) do
    local action_ctx = { opts = action_opts }
    result = group.action(group.items, action_ctx)
    if type(result) == "string" then
      local err = result
      error(err, 0)
    end
    result = require("thetto.lib.async").await_value(result)
  end
  return result
end

return M
