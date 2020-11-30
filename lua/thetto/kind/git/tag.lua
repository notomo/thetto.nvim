local M = {}

M.action_checkout = function(self, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = {"git", "checkout", "-b", item.value, "refs/tags/" .. item.value}
  local job = self.jobs.new(cmd, {on_exit = self.jobs.print_output})
  return nil, job:start()
end

M.action_delete = function(self, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = {"git", "tag", "--delete"}
  table.insert(cmd, table.concat(branches, " "))

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  return nil, job:start()
end

M.default_action = "checkout"

return M
