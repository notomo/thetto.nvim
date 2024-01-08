local M = {}

function M.action_remove(items)
  local ids = vim.tbl_map(function(item)
    return item.image_id
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto2.util.job").promise(cmd)
end

function M.action_untag(items)
  local ids = vim.tbl_map(function(item)
    return item.value
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto2.util.job").promise(cmd)
end

return M
