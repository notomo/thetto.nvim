local M = {}

--- @async
function M.action_remove(items)
  local ids = vim
    .iter(items)
    :map(function(item)
      return item.image_id
    end)
    :totable()
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").await(cmd)
end

--- @async
function M.action_untag(items)
  local ids = vim
    .iter(items)
    :map(function(item)
      return item.value
    end)
    :totable()
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").await(cmd)
end

return M
