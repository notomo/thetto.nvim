local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local item_action_groups = require("thetto.util.action").grouping({ item.item }, {
      action_name = item.value,
      actions = item.metadata.actions,
    })
    require("thetto").execute(item_action_groups, { quit = false })
  end
end

M.default_action = "execute"

return M
