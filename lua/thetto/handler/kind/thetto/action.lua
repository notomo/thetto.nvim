local M = {}

--- @async
function M.action_execute(items)
  return require("thetto.lib.async").all(vim
    .iter(items)
    :map(function(item)
      local action_name = item.value
      --- @async
      return function()
        return require("thetto.util.action").execute(action_name, {}, { quit = false }, function()
          return item.items, item.metadata
        end)
      end
    end)
    :totable())
end

M.default_action = "execute"

return M
