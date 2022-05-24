local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(self, source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/labels"):format(self.opts.owner, self.opts.repo),
    "-F",
    "per_page=100",
  }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local labels = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, label in ipairs(labels) do
        local name = label.name
        local label_desc = label.description
        if not label_desc then
          label_desc = ""
        end
        local desc = ("%s %s"):format(name, label_desc)
        table.insert(items, {
          value = label.name,
          desc = desc,
          label = { owner = self.opts.owner, repo = self.opts.repo },
          column_offsets = { value = 0, description = #name + 1 },
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
    start_key = "description",
  },
})

M.kind_name = "github/label"

return M
