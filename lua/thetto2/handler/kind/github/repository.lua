local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/issue", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_list_pull_request(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/pull_request", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_list_milestone(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/milestone", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_list_release(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/release", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_list_projects(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/project", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_list_action_workflows(items)
  for _, item in ipairs(items) do
    return require("thetto").start("github/action/workflow", {
      source_opts = { owner = item.repo.owner, repo = item.repo.name },
    })
  end
end

function M.action_clone(items)
  local item = items[1]
  if not item then
    return
  end

  local cmd = { "gh", "repo", "clone", item.value }
  return require("thetto2.util.job").promise(cmd)
end

return require("thetto2.core.kind").extend(M, "url")
