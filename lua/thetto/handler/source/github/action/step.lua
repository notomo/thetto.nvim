local timelib = require("thetto.lib.time")

local M = {}

M.opts = { owner = ":owner", repo = ":repo", job_id = nil }

function M.collect(self, source_ctx)
  if not self.opts.job_id then
    return {}
  end

  local path = ("repos/%s/%s/actions/jobs/%s"):format(self.opts.owner, self.opts.repo, self.opts.job_id)
  local cmd = { "gh", "api", "-X", "GET", path }
  return require("thetto.util.job").run(cmd, source_ctx, function(step)
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
    return {
      value = step.name,
      url = ("%s#step:%d:1"):format(step.html_url, step.number),
      step = { run_id = step.run_id },
      desc = desc,
      column_offsets = { value = #mark + 1, state = #title + 1 },
    }
  end, {
    to_outputs = function(job)
      local job_data = vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
      return vim.tbl_map(function(data)
        data.html_url = job_data.html_url
        data.run_id = job_data.run_id
        return data
      end, job_data.steps)
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "state",
  },
})

M.kind_name = "github/action/step"

return M
