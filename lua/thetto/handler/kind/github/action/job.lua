local M = {}

function M.action_list_action_step(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/action/step", {
      source_opts = {owner = item.job.owner, repo = item.job.repo, job_id = item.job.id},
    })
  end
end

M.action_list_children = M.action_list_action_step

return require("thetto.core.kind").extend(M, "url")