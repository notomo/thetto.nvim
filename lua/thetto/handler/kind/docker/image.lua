local M = {}

function M.action_remove(_, items)
  local ids = vim.tbl_map(function(item)
    return item.image_id
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").execute(cmd)
end

function M.action_untag(_, items)
  local ids = vim.tbl_map(function(item)
    return item.value
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").execute(cmd)
end

return M
