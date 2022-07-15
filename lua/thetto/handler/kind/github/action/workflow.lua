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

function M.action_run(self, items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "workflow", "run", item.workflow.file_name }
  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end

  M.action_list_action_run(self, items)

  return job, nil
end

M.action_list_children = M.action_list_action_run

return require("thetto.core.kind").extend(M, "url")
