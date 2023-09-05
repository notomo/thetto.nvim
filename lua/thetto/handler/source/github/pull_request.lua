local M = {}

M.opts = {
  owner = nil,
  repo_with_owner = nil,
  extra_args = {},
  allow_empty_input = false,
}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern and not source_ctx.opts.allow_empty_input then
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
    "prs",
    "--json",
    "author,createdAt,state,title,url,number,isDraft",
  }
  if repo_with_owner and repo_with_owner ~= "" then
    vim.list_extend(cmd, { "--repo", repo_with_owner })
  end
  if owner then
    vim.list_extend(cmd, { "--owner", owner })
  end
  vim.list_extend(cmd, source_ctx.opts.extra_args)
  if pattern then
    vim.list_extend(cmd, vim.split(pattern, "%s+"))
  end

  return require("thetto.util.job").run(cmd, source_ctx, function(pr)
    local mark
    if pr.isDraft then
      mark = "D"
    else
      mark = "R"
    end
    local title = ("%s %s"):format(mark, pr.title)
    local at = pr.createdAt
    local by = "by " .. pr.author.login
    local desc = ("%s %s %s"):format(title, at, by)
    return {
      value = pr.title,
      url = pr.url,
      desc = desc,
      pr = { is_draft = pr.isDraft },
      column_offsets = { value = #mark + 1, at = #title + 1, by = #title + #at + 1 },
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
    else_group = "Comment",
    end_column = 1,
    filter = function(item)
      return not item.pr.is_draft
    end,
  },
  {
    group = "Comment",
    start_key = "at",
    end_key = "by",
  },
})

M.kind_name = "github/pull_request"

M.filters = require("thetto.util.filter").prepend("interactive")

return M
