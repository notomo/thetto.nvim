local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/releases"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
  }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local releases = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, release in ipairs(releases) do
        local mark
        if release.draft then
          mark = "D"
        else
          mark = "R"
        end
        local title = ("%s %s"):format(mark, release.name)
        local desc = ("%s %s"):format(title, release.tag_name)
        table.insert(items, {
          value = release.name,
          url = release.html_url,
          desc = desc,
          release = { is_draft = release.draft, tag_name = release.tag_name },
          column_offsets = { value = #mark + 1, tag_name = #title + 1 },
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
    group = "Comment",
    else_group = "Character",
    end_column = 1,
    filter = function(item)
      return item.release.is_draft
    end,
  },
  {
    group = "Comment",
    start_key = "tag_name",
  },
})

M.kind_name = "url"

return M
