local M = {}

M.opts = {
  owner = nil,
  repo_with_owner = nil,
  extra_args = {},
  milestone = nil,
  labels = {},
  allow_empty_input = false,
}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern and not source_ctx.opts.allow_empty_input then
    return subscriber
  end

  local repo_with_owner = source_ctx.opts.repo_with_owner
  local owner = source_ctx.opts.owner
  if not (owner or repo_with_owner) then
    repo_with_owner =
      vim.fn.systemlist({ "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" })[1]
  end

  local cmd = {
    "gh",
    "search",
    "issues",
    "--json",
    "author,createdAt,state,title,url,number",
  }
  if repo_with_owner and repo_with_owner ~= "" then
    vim.list_extend(cmd, { "--repo", repo_with_owner })
  end
  if owner then
    vim.list_extend(cmd, { "--owner", owner })
  end
  if source_ctx.opts.milestone then
    vim.list_extend(cmd, { "--milestone", source_ctx.opts.milestone })
  end
  for _, label in ipairs(source_ctx.opts.labels) do
    vim.list_extend(cmd, { "--label", label })
  end
  vim.list_extend(cmd, source_ctx.opts.extra_args)
  if pattern then
    vim.list_extend(cmd, vim.split(pattern, "%s+"))
  end

  return require("thetto.util.job").run(cmd, source_ctx, function(issue)
    local mark
    if issue.state == "open" then
      mark = "O"
    else
      mark = "C"
    end
    local value = ("%s #%d %s"):format(mark, issue.number, issue.title)
    local at = "" .. issue.createdAt
    local by = "by " .. issue.author.login
    local desc = ("%s %s %s"):format(value, at, by)
    return {
      value = value,
      url = issue.url,
      desc = desc,
      issue = { is_opened = issue.state == "open" },
      column_offsets = {
        value = 0,
        at = #value + 1,
        by = #value + #at + 1,
      },
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } })
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

M.kind_name = "github/issue"

M.filters = require("thetto.util.filter").prepend("interactive")

return M
