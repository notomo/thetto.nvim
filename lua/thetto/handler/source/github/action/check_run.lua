local timelib = require("thetto.lib.time")

local M = {}

M.opts = { owner = ":owner", repo = ":repo", ref = ":branch" }

function M.collect(source_ctx)
  local path = ("repos/%s/%s/commits/%s/check-runs"):format(
    source_ctx.opts.owner,
    source_ctx.opts.repo,
    source_ctx.opts.ref
  )
  local cmd = { "gh", "api", "-X", "GET", path, "-F", "per_page=100" }
  return require("thetto.util.job").run(cmd, source_ctx, function(job)
    local mark = "  "
    if job.conclusion == "success" then
      mark = "✅"
    elseif job.conclusion == "failure" then
      mark = "❌"
    elseif job.conclusion == "skipped" then
      mark = "🔽"
    elseif job.conclusion == "cancelled" then
      mark = "🚫"
    elseif job.status == "in_progress" then
      mark = "🏃"
    end
    local title = ("%s %s"):format(mark, job.name)
    local states = { job.status }
    if job.conclusion then
      table.insert(states, job.conclusion)
    end
    local state = ("(%s)"):format(table.concat(states, ","))
    local elapsed_seconds = timelib.elapsed_seconds_for_iso_8601(job.started_at, job.completed_at)
    local desc = ("%s %s %s"):format(title, state, timelib.readable(elapsed_seconds))
    local run_id = job.html_url:match("/(%d+)/jobs/%d+$")
    return {
      value = job.name,
      url = job.html_url,
      desc = desc,
      job = { id = job.id },
      run = { id = run_id },
      column_offsets = { value = #mark + 1, state = #title + 1 },
    }
  end, {
    to_outputs = function(output)
      local data = vim.json.decode(output, { luanil = { object = true } })
      return data.check_runs or {}
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "state",
  },
})

M.kind_name = "github/action/job"

return M
