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
  return require("thetto.util.job").run(cmd, source_ctx, function(run)
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
    local elapsed_seconds = timelib.elapsed_seconds_for_iso_8601(run.started_at, run.completed_at)
    local desc = ("%s %s %s"):format(title, state, timelib.readable(elapsed_seconds))
    return {
      value = run.name,
      url = run.html_url,
      desc = desc,
      job = { id = run.id },
      column_offsets = { value = #mark + 1, state = #title + 1 },
    }
  end, {
    to_outputs = function(job)
      local data = vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
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
