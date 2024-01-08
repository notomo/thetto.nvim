local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local item_action_groups = require("thetto2.util.action").grouping({ item.item }, {
      action_name = item.value,
      actions = item.metadata.actions,
    })
    require("thetto2").execute(item_action_groups, { quit = false })
  end
end

M.default_action = "execute"

return M
