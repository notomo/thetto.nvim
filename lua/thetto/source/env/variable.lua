local M = {}

M.collect = function(self)
  -- use `vim.fn.getcompletion("*", "environment")`?
  local job = self.jobs.new({"env"}, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        table.insert(items, {value = output})
      end
      self.append(items)
    end,
  })
  return {}, job
end

M.kind_name = "word"

return M
