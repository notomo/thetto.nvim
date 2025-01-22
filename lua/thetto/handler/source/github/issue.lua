local M = {}

M.opts = {
  owner = nil,
  repo_with_owner = nil,
  extra_args = {},
  milestone = nil,
  labels = {},
  allow_empty_input = false,
  url = nil,
}

function M.get_pattern()
  return vim.fn.input("Pattern: ")
end

function M.collect(source_ctx)
  local pattern = source_ctx.pattern
  if pattern == "" and not source_ctx.opts.allow_empty_input and not source_ctx.opts.url then
    return {}
  end

  local cmd
  if source_ctx.opts.url then
    local repo_with_owner = source_ctx.opts.url:match("https://github.com/([^/]+/[^/]+)")
    if not repo_with_owner then
      return {}
    end
    cmd = {
      "gh",
      "issue",
      "view",
      source_ctx.opts.url,
      "--json",
      "author,createdAt,state,title,url,number",
      "--repo",
      repo_with_owner,
      "--jq",
      "[.]",
    }
  else
    local repo_with_owner = source_ctx.opts.repo_with_owner
    local owner = source_ctx.opts.owner
    if not (owner or repo_with_owner) then
      local o = vim
        .system({ "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" }, { text = true })
        :wait()
      if o.code ~= 0 then
        return vim.trim(o.stderr)
      end
      repo_with_owner = vim.trim(o.stdout)
      vim.print(repo_with_owner)
    end

    cmd = {
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
  end

  return require("thetto.util.job").run(cmd, source_ctx, function(issue)
    local mark
    local is_opened = issue.state:lower() == "open"
    if is_opened then
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
      issue = { is_opened = is_opened },
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

M.modify_pipeline = require("thetto.util.pipeline").prepend({
  require("thetto.util.filter").by_name("source_input"),
})

return M
