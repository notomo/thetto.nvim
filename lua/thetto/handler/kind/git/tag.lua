local M = {}

function M.action_checkout(_, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout", "-b", item.value, "refs/tags/" .. item.value }
  return require("thetto.util.job").execute(cmd)
end

function M.action_delete(_, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "tag", "--delete" }
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").execute(cmd)
end

M.default_action = "checkout"

return M
