local M = {}

function M.action_remove(items)
  local ids = vim
    .iter(items)
    :map(function(item)
      return item.image_id
    end)
    :totable()
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").promise(cmd)
end

function M.action_untag(items)
  local ids = vim
    .iter(items)
    :map(function(item)
      return item.value
    end)
    :totable()
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  return require("thetto.util.job").promise(cmd)
end

return M
