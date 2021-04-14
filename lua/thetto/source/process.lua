local M = {}

function M.collect(self)
  local cmd = {"ps", "--no-headers", "faxo", "pid,user,command"}
  local remove_header = function(_)
  end
  local to_item = function(output)
    local splitted = vim.split(output:gsub("^%s+", ""), "%s")
    return {value = output, pid = splitted[1]}
  end
  if vim.fn.has("mac") == 1 then
    cmd = {"ps", "-axo", "pid,user,command"}
    remove_header = function(outputs)
      table.remove(outputs, 1)
    end
  elseif vim.fn.has("win32") == 1 then
    cmd = {"tasklist", "/NH", "/FO", "CSV"}
    remove_header = function(outputs)
      table.remove(outputs, 1)
    end
    to_item = function(output)
      local splitted = vim.split(output:gsub("^%s+", ""), "\",\"")
      local pid = splitted[2]
      local value = ("%s %d"):format(splitted[1]:sub(2), pid)
      return {value = value, pid = pid}
    end
  end

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      local outputs = job_self:get_stdout()
      remove_header(outputs)
      for _, output in ipairs(outputs) do
        table.insert(items, to_item(output))
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
  })
  return {}, job
end

M.kind_name = "process"

return M
