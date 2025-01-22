local M = {}

function M.execute(action_item_groups, action_opts)
  local Promise = require("thetto.vendor.promise")

  local promise
  for _, group in ipairs(action_item_groups) do
    local action_ctx = { opts = action_opts }
    local result = group.action(group.items, action_ctx)
    if type(result) == "string" then
      local err = result
      local current = promise or Promise.resolve()
      return current:next(function()
        return Promise.reject(err)
      end)
    end

    if not promise then
      -- to remove unneeded promise:next()
      promise = Promise.resolve(result)
    else
      promise = promise:next(function()
        return Promise.resolve(result)
      end)
    end
  end

  return promise or Promise.resolve()
end

return M
