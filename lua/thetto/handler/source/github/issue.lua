local M = {}

M.opts = {
  owner = nil,
  repo_with_owner = nil,
  extra_args = {},
}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local repo_with_owner = source_ctx.opts.repo_with_owner
  local owner = source_ctx.opts.owner
  if not (repo_with_owner or owner) and repo_with_owner ~= "" then
    repo_with_owner =
      vim.fn.systemlist({ "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" })[1]
  end

  local cmd = {
    "gh",
    "search",
    "issues",
    "--json",
    "author,createdAt,state,title,url",
  }
  if repo_with_owner and repo_with_owner ~= "" then
    vim.list_extend(cmd, { "--repo", repo_with_owner })
  end
  if owner then
    vim.list_extend(cmd, { "--owner", owner })
  end
  vim.list_extend(cmd, source_ctx.opts.extra_args)
  vim.list_extend(cmd, vim.split(pattern, "%s+"))

  return require("thetto.util.job").run(cmd, source_ctx, function(issue)
    local mark
    if issue.state == "open" then
      mark = "O"
    else
      mark = "C"
    end
    local title = ("%s %s"):format(mark, issue.title)
    local at = "" .. issue.createdAt
    local by = "by " .. issue.author.login
    local desc = ("%s %s %s"):format(title, at, by)
    return {
      value = issue.title,
      url = issue.url,
      desc = desc,
      issue = { is_opened = issue.state == "open" },
      column_offsets = { value = #mark + 1, at = #title + 1, by = #title + #at + 1 },
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Character",
    else_group = "Boolean",
    end_column = 1,
    filter = function(item)
      return item.issue.is_opened
    end,
  },
  {
    group = "Comment",
    start_key = "at",
    end_key = "by",
  },
})

M.kind_name = "url"

return M
