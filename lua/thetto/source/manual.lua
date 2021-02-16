local M = {}

M.collect = function(self)
  if vim.fn.has("win32") == 1 then
    return nil, nil, "not supported in windows"
  end

  local job = self.jobs.new({"apropos", "."}, {
    on_exit = function(job_self)
      local items = {}
      local outputs = job_self:get_stdout()
      for _, output in ipairs(outputs) do
        local name = table.concat(vim.split(output:gsub("%s+-%s.*", ""), " ", true), "")
        local item = {value = name}
        table.insert(items, item)
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
  })
  return {}, job
end

M.kind_name = "manual"

return M
