local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/actions/workflows"):format(source_ctx.opts.owner, source_ctx.opts.repo),
    "-F",
    "per_page=100",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(workflow)
    local mark
    if workflow.state == "active" then
      mark = "A"
    else
      mark = "D"
    end
    local title = ("%s %s"):format(mark, workflow.name)
    local desc = title
    return {
      value = workflow.name,
      url = workflow.html_url,
      desc = desc,
      workflow = {
        is_active = workflow.state == "active",
        file_name = vim.fs.basename(workflow.path),
      },
      column_offsets = { value = #mark + 1 },
    }
  end, {
    to_outputs = function(output)
      local data = vim.json.decode(output, { luanil = { object = true } })
      return data.workflows or {}
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Character",
    else_group = "Comment",
    end_column = 1,
    filter = function(item)
      return item.workflow.is_active
    end,
  },
})

M.kind_name = "github/action/workflow"

return M
