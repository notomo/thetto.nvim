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

  return require("thetto.util.job").execute(cmd)
end

function M.action_delete(_, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  table.insert(cmd, "--delete")
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").execute(cmd)
end

function M.action_force_delete(_, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  table.insert(cmd, "-D")
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").execute(cmd)
end

M.default_action = "checkout"

return M
