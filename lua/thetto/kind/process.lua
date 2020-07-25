local M = {}

M.cmd = {"kill"}

M.action_kill = function(self, items)
  local pids = {}
  for _, item in ipairs(items) do
    table.insert(pids, item.pid)
  end

  local cmd = vim.deepcopy(M.cmd)
  table.insert(cmd, table.concat(pids, " "))

  local job = self.jobs.new(cmd, {on_exit = self.jobs.print_output})
  job:start()

  return job
end

return M
