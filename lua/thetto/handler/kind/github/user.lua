local M = {}

function M.action_list_repository(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/user_repository", {
      opts = { owner = item.user.name, is_org = item.user.is_org },
    })
    return require("thetto").start(source)
  end
end

M.action_list_children = M.action_list_repository

return require("thetto.core.kind").extend(M, "url")
