local M = {}

function M.action_checkout(_, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout", "-b", item.value, "refs/tags/" .. item.value }
  local job = require("thetto.lib.job").new(cmd, { on_exit = require("thetto.lib.job").print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

function M.action_delete(_, items)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "tag", "--delete" }
  vim.list_extend(cmd, branches)

  local job = require("thetto.lib.job").new(cmd, {
    on_exit = require("thetto.lib.job").print_stdout,
    on_stderr = require("thetto.lib.job").print_stderr,
  })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

M.default_action = "checkout"

return M
