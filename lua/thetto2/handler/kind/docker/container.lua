local M = {}

function M.action_remove(items)
  local ids = vim.tbl_map(function(item)
    return item.container_id
  end, items)
  local cmd = { "docker", "rm" }
  vim.list_extend(cmd, ids)
  return require("thetto2.util.job").promise(cmd)
end

return M
