local M = {}

function M.action_list_action_job(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/action/job", {
      source_opts = { owner = item.step.owner, repo = item.step.repo, run_id = item.step.run_id },
    })
  end
end

M.action_list_parents = M.action_list_action_job

return require("thetto.core.kind").extend(M, "url")
