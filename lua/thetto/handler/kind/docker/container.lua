local M = {}

--- @async
function M.action_remove(items)
  local ids = vim
    .iter(items)
    :map(function(item)
      return item.container_id
    end)
    :totable()
  local cmd = { "docker", "rm" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").await(cmd)
end

return M
