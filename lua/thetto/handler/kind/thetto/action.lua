local M = {}

function M.action_execute(items)
  return require("thetto.vendor.promise").all(vim
    .iter(items)
    :map(function(item)
      local action_name = item.value
      return require("thetto.util.action").execute(action_name, {}, { quit = false }, function()
        return item.items, item.metadata
      end)
    end)
    :totable())
end

M.default_action = "execute"

return M
