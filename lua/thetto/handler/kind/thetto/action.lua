local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local action_name = item.value
    require("thetto.util.action").execute(action_name, {}, { quit = false }, function()
      return { item.item }, item.metadata
    end)
  end
end

M.default_action = "execute"

return M
