local M = {}

function M.action_list_action_job(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/action/job", {
      opts = { owner = item.run.owner, repo = item.run.repo, run_id = item.run.id },
    })
    return require("thetto").start(source)
  end
end

M.action_list_children = M.action_list_action_job

return require("thetto.core.kind").extend(M, "url")
