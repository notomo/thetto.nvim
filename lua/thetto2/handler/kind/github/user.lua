local M = {}

function M.action_list_repository(items)
  for _, item in ipairs(items) do
    local source = require("thetto2.util.source").by_name("github/user_repository", {
      opts = { owner = item.user.name, is_org = item.user.is_org },
    })
    return require("thetto2").start(source)
  end
end

M.action_list_children = M.action_list_repository

return require("thetto2.core.kind").extend(M, "url")
