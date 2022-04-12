local M = {}

M.opts = { checkout = { track = false }, delete = { force = false } }

function M.action_checkout(self, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout" }
  if self.action_opts["track"] then
    table.insert(cmd, "-t")
  end
  table.insert(cmd, item.value)

  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

function M.action_delete(self, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  table.insert(cmd, "--delete")
  vim.list_extend(cmd, branches)

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

function M.action_force_delete(self, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  table.insert(cmd, "-D")
  vim.list_extend(cmd, branches)

  local job = self.jobs.new(cmd, {
    on_exit = self.jobs.print_stdout,
    on_stderr = self.jobs.print_stderr,
  })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

M.default_action = "checkout"

return M
