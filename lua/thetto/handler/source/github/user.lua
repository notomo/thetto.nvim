local M = {}

function M.collect(self, source_ctx)
  local pattern = source_ctx.pattern
  if not pattern then
    pattern = vim.fn.input("Pattern: ")
  end
  if not pattern or pattern == "" then
    return {}, nil, self.errors.skip_empty_pattern
  end

  local cmd = { "gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local data = vim.json.decode(job_self:get_joined_stdout(), { luanil = { object = true } })
      for _, user in ipairs(data.items) do
        table.insert(items, {
          value = user.login,
          url = user.html_url,
          user = { name = user.login, is_org = user.type == "Organization" },
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = source_ctx.cwd,
  })
  return {}, job
end

M.kind_name = "github/user"

return M
