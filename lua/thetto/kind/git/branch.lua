local M = {}

M.opts = {checkout = {track = false}, delete = {force = false}}

M.action_checkout = function(self, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = {"git", "checkout"}
  if self.action_opts["track"] then
    table.insert(cmd, "-t")
  end
  table.insert(cmd, item.value)

  local job = self.jobs.new(cmd, {on_exit = self.jobs.print_output})
  job:start()
end

M.action_delete = function(self, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = {"git", "branch"}
  if self.action_opts["force"] then
    table.insert(cmd, "-D")
  else
    table.insert(cmd, "--delete")
  end
  table.insert(cmd, table.concat(branches, " "))

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  job:start()
end

M.default_action = "checkout"

return M
