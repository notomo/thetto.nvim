local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/actions/workflows"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
  }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, workflow in ipairs(data.workflows or {}) do
        local mark
        if workflow.state == "active" then
          mark = "A"
        else
          mark = "D"
        end
        local title = ("%s %s"):format(mark, workflow.name)
        local desc = title
        table.insert(items, {
          value = workflow.name,
          url = workflow.html_url,
          desc = desc,
          workflow = {
            is_active = workflow.state == "active",
            file_name = vim.fn.fnamemodify(workflow.path, ":t"),
          },
          column_offsets = { value = #mark + 1 },
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
