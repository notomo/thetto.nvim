local M = {}

local to_git_root = require("thetto.handler.kind.git._util").to_git_root

function M.action_checkout(items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout", "-b", item.value, "refs/tags/" .. item.value }
  return require("thetto.util.job").promise(cmd, { cwd = item.git_root })
end

function M.action_delete(items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "tag", "--delete" }
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").promise(cmd, { cwd = to_git_root(items) })
end

M.default_action = "checkout"

return M
