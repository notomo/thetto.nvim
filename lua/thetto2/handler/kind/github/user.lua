local M = {}

function M.action_list_repository(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/user_repository", {
      source_opts = { owner = item.user.name, is_org = item.user.is_org },
    })
  end
end

M.action_list_children = M.action_list_repository

return require("thetto.core.kind").extend(M, "url")
