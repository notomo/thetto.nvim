local M = {}

function M.action_list_issue(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/issue", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_list_pull_request(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/pull_request", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_list_milestone(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/milestone", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_list_release(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/release", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_list_projects(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/project", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_list_action_workflows(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/action/workflow", {
      opts = { owner = item.repo.owner, repo = item.repo.name },
    })
    return require("thetto").start(source)
  end
end

function M.action_clone(items)
  local item = items[1]
  if not item then
    return
  end

  local cmd = { "gh", "repo", "clone", item.value }
  return require("thetto.util.job").promise(cmd)
end

return require("thetto.core.kind").extend(M, "url")
