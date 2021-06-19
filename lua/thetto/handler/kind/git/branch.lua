local M = {}

M.opts = {checkout = {track = false}, delete = {force = false}}

function M.action_checkout(self, items)
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
  return nil, job:start()
end

function M.action_delete(self, items)
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
  vim.list_extend(cmd, branches)

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  return nil, job:start()
end

M.default_action = "checkout"

return M
