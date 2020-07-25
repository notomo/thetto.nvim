local M = {}

M.cmd = {"ps", "--no-headers", "faxo", "pid,user,command"}

M.collect = function(self)
  local job = self.jobs.new(M.cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local splitted = vim.split(output:gsub("^%s+", ""), "%s")
        table.insert(items, {value = output, pid = splitted[1]})
      end
      self.append(items)
    end,
    on_stderr = self.jobs.print_stderr,
  })
  return {}, job
end

M.kind_name = "process"

return M
