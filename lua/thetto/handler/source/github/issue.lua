local M = {}

M.opts = {
  owner = ":owner",
  repo = ":repo",
  milestone = nil,
  labels = {},
  assignee = nil,
  state = "open",
}

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/issues"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=" .. self.opts.state,
  }
  if self.opts.milestone then
    vim.list_extend(cmd, { "-F", "milestone=" .. self.opts.milestone })
  end
  if #self.opts.labels > 0 then
    vim.list_extend(cmd, { "-F", "labels=" .. table.concat(self.opts.labels, ",") })
  end
  if self.opts.assignee then
    vim.list_extend(cmd, { "-F", "assignee=" .. self.opts.assignee })
  end

  return require("thetto.util").job.run(cmd, source_ctx, function(issue)
    local mark
    if issue.state == "open" then
      mark = "O"
    else
      mark = "C"
    end
    local title = ("%s %s"):format(mark, issue.title)
    local at = "" .. issue.created_at
    local by = "by " .. issue.user.login
    local desc = ("%s %s %s"):format(title, at, by)
    return {
      value = issue.title,
      url = issue.html_url,
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

M.highlight = require("thetto.util").highlight.columns({
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
