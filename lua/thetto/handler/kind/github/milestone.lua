local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/issue", {
      source_opts = {
        milestone = item.milestone.number,
        owner = item.milestone.owner,
        repo = item.milestone.repo,
      },
    })
  end
end

return require("thetto.core.kind").extend(M, "url")
