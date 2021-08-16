local M = {}

function M.collect(self, opts)
  local cmd = {"gh", "api", "-X", "GET", "user/starred", "-F", "per_page=100"}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end

      local items = {}
      local repos = vim.fn.json_decode(job_self:get_stdout())
      for _, repo in ipairs(repos) do
        table.insert(items, {
          value = repo.full_name,
          url = repo.html_url,
          repo = {owner = repo.owner.login, name = repo.name},
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })
  return {}, job
end

M.kind_name = "github/repository"

return M