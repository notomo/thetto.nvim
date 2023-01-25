local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/issue", {
      source_opts = {
        labels = { item.value },
        allow_empty_input = true,
      },
    })
  end
end

M.action_list_children = M.action_list_issue

M.default_action = "list_issue"

return M
