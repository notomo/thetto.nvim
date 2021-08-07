local M = {}

function M.action_list_action_run(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/action/run", {
      source_opts = {
        owner = item.workflow.owner,
        repo = item.workflow.repo,
        workflow_file_name = item.workflow.file_name,
      },
    })
  end
end

return require("thetto.core.kind").extend(M, "url")
