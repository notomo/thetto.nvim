local M = {}

function M.execute(action_item_groups)
  local Promise = require("thetto.vendor.promise")

  local promise
  for _, group in ipairs(action_item_groups) do
    local result, err = group.action(group.items)
    if err then
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
