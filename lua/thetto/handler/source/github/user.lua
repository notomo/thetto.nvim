local M = {}

function M.collect(self, opts)
  local pattern = opts.pattern
  if not pattern then
    pattern = vim.fn.input("Pattern: ")
  end
  if not pattern or pattern == "" then
    return {}, nil, self.errors.skip_empty_pattern
  end

  local cmd = {"gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.fn.json_decode(job_self:get_stdout())
      for _, user in ipairs(data.items) do
        table.insert(items, {
          value = user.login,
          url = user.html_url,
          user = {name = user.login, is_org = user.type == "Organization"},
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })
  return {}, job
end

M.kind_name = "github/user"

return M
