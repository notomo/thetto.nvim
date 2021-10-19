local M = {}

M.opts = {owner = ":owner", repo = ":repo"}

function M.collect(self, opts)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/projects"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=open",
    "-H",
    "Accept: application/vnd.github.inertia-preview+json",
  }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local projects = vim.json.decode(job_self:get_joined_stdout(), {luanil = {object = true}})
      for _, project in ipairs(projects) do
        local mark
        if project.state == "open" then
          mark = "O"
        else
          mark = "C"
        end

        local project_name = project.name

        local project_desc = project.body:gsub("\n", " "):gsub("\r", " ")
        if not project_desc then
          project_desc = ""
        end

        local desc = ("%s %s %s"):format(mark, project_name, project_desc)
        table.insert(items, {
          value = project.name,
          url = project.html_url,
          desc = desc,
          project = {
            is_opened = project.state == "open",
            id = project.id,
            owner = self.opts.owner,
            repo = self.opts.repo,
          },
          column_offsets = {value = #mark + 1, description = #mark + #project_name + 1},
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
    if item.project.is_opened then
      highlighter:add("Character", first_line + i - 1, 0, 1)
    else
      highlighter:add("Boolean", first_line + i - 1, 0, 1)
    end
    highlighter:add("Comment", first_line + i - 1, item.column_offsets.description, -1)
  end
end

M.kind_name = "url"

return M
