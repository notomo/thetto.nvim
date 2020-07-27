local M = {}

M.get_command = function(path)
  return {"find", "-L", path, "-type", "d", "-name", ".git", "-prune", "-o", "-type", "f", "-print"}
end

M.collect = function(self, opts)
  local cmd = M.get_command(opts.cwd)
  local buffered_items = {}
  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      if data == nil then
        return
      end

      local outputs = job_self.parse_output(data)
      for _, path in ipairs(outputs) do
        if path == "" then
          goto continue
        end
        local relative_path = path:gsub("^" .. opts.cwd .. "/", "")
        table.insert(buffered_items, {value = relative_path, path = path})
        ::continue::
      end
    end,
    on_exit = function(_)
      self.append(buffered_items)
      buffered_items = {}
    end,
    on_interval = function(_)
      self.append(buffered_items)
      buffered_items = {}
    end,
    stdout_buffered = false,
    stderr_buffered = false,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "file"

return M
