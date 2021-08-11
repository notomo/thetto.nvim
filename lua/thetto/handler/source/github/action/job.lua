local M = {}

M.opts = {owner = ":owner", repo = ":repo", run_id = nil}

function M.collect(self, opts)
  if not self.opts.run_id then
    return {}
  end

  local path = ("repos/%s/%s/actions/runs/%s/jobs"):format(self.opts.owner, self.opts.repo, self.opts.run_id)
  local cmd = {"gh", "api", "-X", "GET", path, "-F", "per_page=100"}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.fn.json_decode(job_self:get_stdout())
      for _, job in ipairs(data.jobs or {}) do
        local mark = "  "
        if job.conclusion == "success" then
          mark = "✅"
        elseif job.conclusion == "failure" then
          mark = "❌"
        elseif job.conclusion == "skipped" then
          mark = "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
        elseif job.conclusion == "cancelled" then
          mark = "🚫󠁧󠁢󠁷󠁬󠁳󠁿"
        elseif job.status == "in_progress" then
          mark = "🏃"
        end
        local title = ("%s %s"):format(mark, job.name)
        local states = {job.status}
        if job.conclusion then
          table.insert(states, job.conclusion)
        end
        local state = ("(%s)"):format(table.concat(states, ","))
        local elapsed_seconds = self.timelib.elapsed_seconds_for_iso_8601(job.started_at, job.completed_at)
        local desc = ("%s %s %s"):format(title, state, self.timelib.readable(elapsed_seconds))
        table.insert(items, {
          value = job.name,
          url = job.html_url,
          desc = desc,
          job = {id = job.id},
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

M.kind_name = "url"

return M
