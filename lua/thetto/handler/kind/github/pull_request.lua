local M = {}

function M.action_checkout(_, items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "pr", "checkout", item.url }
  local job = require("thetto.lib.job").new(cmd, { on_exit = require("thetto.lib.job").print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

return require("thetto.core.kind").extend(M, "url")
