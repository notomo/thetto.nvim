local M = {}

M.collect = function(self)
  local cmd = {"ps", "--no-headers", "faxo", "pid,user,command"}
  local remove_header = function(_)
  end
  if vim.fn.has("mac") then
    cmd = {"ps", "-axo", "pid,user,command"}
    remove_header = function(outputs)
      table.remove(outputs, 1)
    end
  end

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      local outputs = job_self:get_stdout()
      remove_header(outputs)
      for _, output in ipairs(outputs) do
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
