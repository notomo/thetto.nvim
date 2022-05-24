local timelib = require("thetto.lib.time")

local M = {}

M.opts = { owner = ":owner", repo = ":repo", job_id = nil }

function M.collect(self, source_ctx)
  if not self.opts.job_id then
    return {}
  end

  local path = ("repos/%s/%s/actions/jobs/%s"):format(self.opts.owner, self.opts.repo, self.opts.job_id)
  local cmd = { "gh", "api", "-X", "GET", path }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local job = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, step in ipairs(job.steps) do
        local mark = "  "
        if step.conclusion == "success" then
          mark = "✅"
        elseif step.conclusion == "failure" then
          mark = "❌"
        elseif step.conclusion == "skipped" then
          mark = "🔽"
        elseif step.conclusion == "cancelled" then
          mark = "🚫"
        elseif step.status == "in_progress" then
          mark = "🏃"
        end
        local title = ("%s %s"):format(mark, step.name)
        local states = { step.status }
        if step.conclusion then
          table.insert(states, step.conclusion)
        end
        local state = ("(%s)"):format(table.concat(states, ","))
        local elapsed_seconds = timelib.elapsed_seconds_for_iso_8601(step.started_at, step.completed_at)
        local desc = ("%s %s %s"):format(title, state, timelib.readable(elapsed_seconds))
        table.insert(items, {
          value = step.name,
          url = ("%s#step:%d:1"):format(job.html_url, step.number),
          step = { run_id = job.run_id },
          desc = desc,
          column_offsets = { value = #mark + 1, state = #title + 1 },
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
    group = "Comment",
    start_key = "state",
  },
})

M.kind_name = "github/action/step"

return M
