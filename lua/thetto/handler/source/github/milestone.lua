local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(self, opts)
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
    cwd = opts.cwd,
  })
  return {}, job
end

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  for i, item in ipairs(items) do
    if item.milestone.is_opened then
      highlighter:add("Character", first_line + i - 1, 0, 1)
    else
      highlighter:add("Boolean", first_line + i - 1, 0, 1)
    end
    highlighter:add("Comment", first_line + i - 1, item.column_offsets.description, -1)
  end
end

M.kind_name = "github/milestone"

return M
