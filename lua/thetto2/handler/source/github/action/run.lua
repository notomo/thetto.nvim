local M = {}

M.opts = { owner = ":owner", repo = ":repo", workflow_file_name = nil }

function M.collect(source_ctx)
  local path
  if source_ctx.opts.workflow_file_name then
    path = ("repos/%s/%s/actions/workflows/%s/runs"):format(
      source_ctx.opts.owner,
      source_ctx.opts.repo,
      source_ctx.opts.workflow_file_name
    )
  else
    path = ("repos/%s/%s/actions/runs"):format(source_ctx.opts.owner, source_ctx.opts.repo)
  end

  local cmd = { "gh", "api", "-X", "GET", path, "-F", "per_page=100" }
  return require("thetto2.util.job").run(cmd, source_ctx, function(run)
    local mark = require("thetto2.handler.source.github.action._util").conclusion_mark(run)
    local title = ("%s %s"):format(mark, run.name)
    local state = require("thetto2.handler.source.github.action._util").state(run)
    local branch = ("[%s]"):format(run.head_branch)
    local desc = ("%s %s %s"):format(title, branch, state)
    return {
      value = run.name,
      url = run.html_url,
      desc = desc,
      run = { branch = run.head_branch, id = run.id },
      column_offsets = { value = #mark + 1, branch = #title + 1, state = #title + #branch + 1 },
    }
  end, {
    to_outputs = function(output)
      local data = vim.json.decode(output, { luanil = { object = true } })
      return data.workflow_runs or {}
    end,
  })
end

M.highlight = require("thetto2.util.highlight").columns({
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
