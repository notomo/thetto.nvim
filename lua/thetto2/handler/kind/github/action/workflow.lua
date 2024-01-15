local M = {}

function M.action_list_action_run(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end
  local source = require("thetto2.util.source").by_name("github/action/run", {
    opts = {
      owner = item.workflow.owner,
      repo = item.workflow.repo,
      workflow_file_name = item.workflow.file_name,
    },
  })
  return require("thetto2").start(source)
end

function M.action_run(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "workflow", "run", item.workflow.file_name }
  return require("thetto2.util.job").promise(cmd):next(M.action_list_action_run)
end

M.action_list_children = M.action_list_action_run

return require("thetto2.core.kind").extend(M, "url")
