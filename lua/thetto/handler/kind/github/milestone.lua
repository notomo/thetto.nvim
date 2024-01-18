local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/issue", {
      opts = {
        milestone = item.value,
        allow_empty_input = true,
      },
    })
    return require("thetto").start(source)
  end
end

M.action_list_children = M.action_list_issue

return require("thetto.core.kind").extend(M, "url")
