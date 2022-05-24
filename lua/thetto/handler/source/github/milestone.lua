local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/milestones"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=all",
  }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local milestones = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, milestone in ipairs(milestones) do
        local mark
        if milestone.state == "open" then
          mark = "O"
        else
          mark = "C"
        end

        local milestone_title = milestone.title

        local milestone_desc = milestone.description
        if not milestone_desc then
          milestone_desc = ""
        end
        milestone_desc = milestone_desc:gsub("\n", " "):gsub("\r", " ")

        local title = ("%s %s %s"):format(mark, milestone_title, milestone_desc)
        local desc = title
        table.insert(items, {
          value = milestone.title,
          url = milestone.html_url,
          desc = desc,
          milestone = {
            is_opened = milestone.state == "open",
            number = milestone.number,
            owner = self.opts.owner,
            repo = self.opts.repo,
          },
          column_offsets = { value = #mark + 1, description = #mark + #milestone_title + 1 },
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
    else_group = "Boolean",
    end_column = 1,
    filter = function(item)
      return item.milestone.is_opened
    end,
  },
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "github/milestone"

return M
