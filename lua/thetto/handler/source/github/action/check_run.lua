local M = {}

M.opts = {owner = ":owner", repo = ":repo", ref = ":branch"}

function M.collect(self, opts)
  local path = ("repos/%s/%s/commits/%s/check-runs"):format(self.opts.owner, self.opts.repo, self.opts.ref)
  local cmd = {"gh", "api", "-X", "GET", path, "-F", "per_page=100"}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.fn.json_decode(job_self:get_stdout())
      for _, run in ipairs(data.check_runs or {}) do
        local mark = "  "
        if run.conclusion == "success" then
          mark = "✅"
        elseif run.conclusion == "failure" then
          mark = "❌"
        elseif run.conclusion == "skipped" then
          mark = "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
        elseif run.conclusion == "cancelled" then
          mark = "🚫󠁧󠁢󠁷󠁬󠁳󠁿"
        elseif run.status == "in_progress" then
          mark = "🏃"
        end
        local title = ("%s %s"):format(mark, run.name)
        local states = {run.status}
        if run.conclusion then
          table.insert(states, run.conclusion)
        end
        local state = ("(%s)"):format(table.concat(states, ","))
        local desc = ("%s %s"):format(title, state)
        table.insert(items, {
          value = run.name,
          url = run.html_url,
          desc = desc,
          run = {id = run.id},
          column_offsets = {value = #mark + 1, state = #title + 1},
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
    highlighter:add("Comment", first_line + i - 1, item.column_offsets.state, -1)
  end
end

M.kind_name = "github/action/run"

return M
