local M = {}

M.cmd = { "kill" }

function M.action_kill(items)
  local pids = {}
  for _, item in ipairs(items) do
    table.insert(pids, item.pid)
  end

  local cmd = vim.deepcopy(M.cmd)
  vim.list_extend(cmd, pids)

  return require("thetto.util.job").execute(cmd)
end

return M
