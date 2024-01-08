local timelib = require("thetto2.lib.time")

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
  return require("thetto2.util.job").run(cmd, source_ctx, function(job)
    local mark = require("thetto2.handler.source.github.action._util").conclusion_mark(job)
    local title = ("%s %s"):format(mark, job.name)
    local state = require("thetto2.handler.source.github.action._util").state(job)
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
      return data.jobs or {}
    end,
  })
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    start_key = "state",
  },
})

M.kind_name = "github/action/job"

return M
