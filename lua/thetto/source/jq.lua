local M = {}

M.collect = function(self, opts)
  local pattern = opts.pattern
  if pattern == nil or pattern == "" then
    if opts.interactive then
      self:append({})
    end
    return {}, nil, self.errors.skip_empty_pattern
  end

  local cmd = {"jq", pattern}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      local outputs = job_self:get_stdout()
      for _, output in ipairs(outputs) do
        table.insert(items, {value = output})
      end
      self:append(items)
    end,
    on_stderr = function(job_self)
      local items = {}
      local outputs = job_self:get_stderr()
      for _, output in ipairs(outputs) do
        table.insert(items, {value = output})
      end
      self:reset()
      self:append(items)
    end,
  })
  local err = job:start()
  if err ~= nil then
    return nil, nil, err
  end

  local str = table.concat(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false), "\n")
  job.stdin:write(str)
  job.stdin:close()

  return {}, job
end

M.kind_name = "word"

return M
