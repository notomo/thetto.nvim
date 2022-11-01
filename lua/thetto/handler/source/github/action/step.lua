local timelib = require("thetto.lib.time")

local M = {}

M.opts = { owner = ":owner", repo = ":repo", job_id = nil }

function M.collect(source_ctx)
  if not source_ctx.opts.job_id then
    return {}
  end

  local path = ("repos/%s/%s/actions/jobs/%s"):format(
    source_ctx.opts.owner,
    source_ctx.opts.repo,
    source_ctx.opts.job_id
  )
  local cmd = { "gh", "api", "-X", "GET", path }
  return require("thetto.util.job").run(cmd, source_ctx, function(step)
    local mark = require("thetto.handler.source.github.action._util").conclusion_mark(step)
    local title = ("%s %s"):format(mark, step.name)
    local state = require("thetto.handler.source.github.action._util").state(step)
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
    to_outputs = function(output)
      local job_data = vim.json.decode(output, { luanil = { object = true } })
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
