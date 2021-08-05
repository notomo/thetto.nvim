local M = {}

function M.action_list_issue(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/issue", {source_opts = {milestone = item.milestone.number}})
  end
end

return require("thetto.core.kind").extend(M, require("thetto.handler.kind.url"))
