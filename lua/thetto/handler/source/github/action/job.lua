local timelib = require("thetto.lib.time")

local M = {}

M.opts = { owner = ":owner", repo = ":repo", run_id = nil }

function M.collect(source_ctx)
  if not source_ctx.opts.run_id then
    return {}
  end

  local path = ("repos/%s/%s/actions/runs/%s/jobs"):format(
    source_ctx.opts.owner,
    source_ctx.opts.repo,
    source_ctx.opts.run_id
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
    return {
      value = job.name,
      url = job.html_url,
      desc = desc,
      job = { id = job.id },
      column_offsets = { value = #mark + 1, state = #title + 1 },
    }
  end, {
    to_outputs = function(job)
      local data = vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
      return data.jobs or {}
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
