local M = {}

M.cmd = { "kill" }

function M.action_kill(_, items)
  local pids = {}
  for _, item in ipairs(items) do
    table.insert(pids, item.pid)
  end

  local cmd = vim.deepcopy(M.cmd)
  vim.list_extend(cmd, pids)

  local job = require("thetto.lib.job").new(cmd, { on_exit = require("thetto.lib.job").print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end

  return job, nil
end

return M
