local M = {}

M.opts = {merged = false}

M.collect = function(self, opts)
  local _, err = self.filelib.find_git_root()
  if err ~= nil then
    return {}, nil, err
  end

  local cmd = {"git", "tag", "-l"}
  if self.opts.merged then
    table.insert(cmd, "--merged")
  end

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        table.insert(items, {value = output})
      end
      self.append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "git/tag"

return M
