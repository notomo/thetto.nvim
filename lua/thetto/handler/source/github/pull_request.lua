local M = {}

M.opts = {
  owner = ":owner",
  repo = ":repo",
  state = "open",
  sort = "created",
  sort_direction = "desc",
}

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/pulls"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=" .. self.opts.state,
    "-F",
    "sort=" .. self.opts.sort,
    "-F",
    "direction=" .. self.opts.sort_direction,
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(pr)
    local mark
    if pr.draft then
      mark = "D"
    else
      mark = "R"
    end
    local title = ("%s %s"):format(mark, pr.title)
    local at = pr.created_at
    local by = "by " .. pr.user.login
    local branch = pr.head.ref
    local desc = ("%s %s %s (%s)"):format(title, at, by, branch)
    return {
      value = pr.title,
      url = pr.html_url,
      desc = desc,
      pr = { is_draft = pr.draft },
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

return M
