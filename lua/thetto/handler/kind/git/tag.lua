local M = {}

function M.action_checkout(self, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout", "-b", item.value, "refs/tags/" .. item.value }
  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  return nil, job:start()
end

function M.action_delete(self, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "tag", "--delete" }
  vim.list_extend(cmd, branches)

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  return nil, job:start()
end

M.default_action = "checkout"

return M
