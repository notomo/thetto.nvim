local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    require("thetto").start("github/issue", {
      source_opts = { labels = { item.value }, owner = item.label.owner, repo = item.label.repo },
    })
  end
end

M.default_action = "list_issue"

return M
