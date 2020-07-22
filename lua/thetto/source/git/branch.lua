local M = {}

M.make = function(self, opts)
  local cmd = {"git", "branch", "--format", "%(refname:short)"}
  if self.opts.all then
    table.insert(cmd, "--all")
  end

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        table.insert(items, {value = output})
      end
      self.set(items)
    end,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "git/branch"

return M
