local M = {}

function M.action_remove(_, items)
  local ids = vim.tbl_map(function(item)
    return item.image_id
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  local job = require("thetto.lib.job").new(cmd, { on_exit = require("thetto.lib.job").print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

function M.action_untag(_, items)
  local ids = vim.tbl_map(function(item)
    return item.value
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  local job = require("thetto.lib.job").new(cmd, { on_exit = require("thetto.lib.job").print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

return M
