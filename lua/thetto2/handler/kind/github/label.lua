local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    local source = require("thetto2.util.source").by_name("github/issue", {
      opts = {
        labels = { item.value },
        allow_empty_input = true,
      },
    })
    return require("thetto2").start(source)
  end
end

M.action_list_children = M.action_list_issue

M.default_action = "list_issue"

return M
