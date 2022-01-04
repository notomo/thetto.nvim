local M = {}

function M.action_list_action_job(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/action/job", {
      source_opts = { owner = item.run.owner, repo = item.run.repo, run_id = item.run.id },
    })
  end
end

M.action_list_children = M.action_list_action_job

return require("thetto.core.kind").extend(M, "url")
