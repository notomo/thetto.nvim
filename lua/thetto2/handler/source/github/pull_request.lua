local M = {}

M.opts = {
  owner = nil,
  repo_with_owner = nil,
  extra_args = {},
  allow_empty_input = true,
  state = "open",
  url = nil,
}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto2.util.source").get_input(source_ctx)
  if not pattern and not source_ctx.opts.allow_empty_input and not source_ctx.opts.url then
    return subscriber
  end

  local cmd
  if source_ctx.opts.url then
    local repo_with_owner = source_ctx.opts.url:match("https://github.com/([^/]+/[^/]+)")
    if not repo_with_owner then
      return {}
    end
    cmd = {
      "gh",
      "pr",
      "view",
      source_ctx.opts.url,
      "--json",
      "author,createdAt,state,title,url,number,isDraft",
      "--repo",
      repo_with_owner,
      "--jq",
      "[.]",
    }
  else
    local repo_with_owner = source_ctx.opts.repo_with_owner
    local owner = source_ctx.opts.owner
    if not (owner or repo_with_owner) then
      repo_with_owner =
        vim.fn.systemlist({ "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" })[1]
    end

    cmd = {
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
    if source_ctx.opts.state ~= "" then
      vim.list_extend(cmd, { "--state", source_ctx.opts.state })
    end
    vim.list_extend(cmd, source_ctx.opts.extra_args)
    if pattern then
      vim.list_extend(cmd, vim.split(pattern, "%s+"))
    end
  end

  return require("thetto2.util.job").run(cmd, source_ctx, function(pr)
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

M.highlight = require("thetto2.util.highlight").columns({
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

M.modify_pipeline = require("thetto2.util.pipeline").prepend({
  require("thetto2.util.filter").by_name("source_input"),
})

return M
