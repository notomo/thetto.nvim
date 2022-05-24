local M = {}

M.opts = { owner = ":owner", repo = ":repo", workflow_file_name = nil }

function M.collect(self, source_ctx)
  local path
  if self.opts.workflow_file_name then
    path = ("repos/%s/%s/actions/workflows/%s/runs"):format(
      self.opts.owner,
      self.opts.repo,
      self.opts.workflow_file_name
    )
  else
    path = ("repos/%s/%s/actions/runs"):format(self.opts.owner, self.opts.repo)
  end
  local cmd = { "gh", "api", "-X", "GET", path, "-F", "per_page=100" }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, run in ipairs(data.workflow_runs or {}) do
        local mark = "  "
        if run.conclusion == "success" then
          mark = "✅"
        elseif run.conclusion == "failure" then
          mark = "❌"
        elseif run.conclusion == "skipped" then
          mark = "🔽"
        elseif run.conclusion == "cancelled" then
          mark = "🚫"
        elseif run.status == "in_progress" then
          mark = "🏃"
        end
        local title = ("%s %s"):format(mark, run.name)
        local states = { run.status }
        if run.conclusion then
          table.insert(states, run.conclusion)
        end
        local state = ("(%s)"):format(table.concat(states, ","))
        local branch = ("[%s]"):format(run.head_branch)
        local desc = ("%s %s %s"):format(title, branch, state)
        table.insert(items, {
          value = run.name,
          url = run.html_url,
          desc = desc,
          run = { branch = run.head_branch, id = run.id },
          column_offsets = { value = #mark + 1, branch = #title + 1, state = #title + #branch + 1 },
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = source_ctx.cwd,
  })
  return {}, job
end

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "Conditional",
    start_key = "branch",
    end_key = "state",
  },
  {
    group = "Comment",
    start_key = "state",
  },
})

M.kind_name = "github/action/run"

return M
