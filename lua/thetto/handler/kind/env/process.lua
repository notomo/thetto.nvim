local M = {}

if vim.fn.has("win32") == 1 then
  M.get_cmds = function(pids)
    return vim
      .iter(pids)
      :map(function(pid)
        return { "taskkill", "/pid", pid, "/F" }
      end)
      :totable()
  end
else
  M.get_cmds = function(pids)
    local cmd = { "kill" }
    vim.list_extend(cmd, pids)
    return { cmd }
  end
end

--- @async
function M.action_kill(items)
  local pids = vim
    .iter(items)
    :map(function(item)
      return item.pid
    end)
    :totable()

  local cmds = M.get_cmds(pids)
  return require("thetto.lib.async").all_settled(vim
    .iter(cmds)
    :map(function(cmd)
      --- @async
      return function()
        return require("thetto.util.job").await(cmd)
      end
    end)
    :totable())
end

return M
