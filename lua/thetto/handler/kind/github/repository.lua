local M = {}

function M.action_list_issue(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/issue", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

function M.action_list_pull_request(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/pull_request", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

function M.action_list_milestone(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/milestone", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

function M.action_list_release(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/release", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

function M.action_list_projects(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/project", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

function M.action_list_action_workflows(_, items)
  for _, item in ipairs(items) do
    require("thetto").start("github/action/workflow", {
      source_opts = {owner = item.repo.owner, repo = item.repo.name},
    })
  end
end

return require("thetto.core.kind").extend(M, "url")
