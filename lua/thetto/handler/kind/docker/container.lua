local M = {}

function M.action_remove(_, items)
  local ids = vim.tbl_map(function(item)
    return item.container_id
  end, items)
  local cmd = { "docker", "rm" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").execute(cmd)
end

return M
