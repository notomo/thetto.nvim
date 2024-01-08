local M = {}

if vim.fn.has("win32") == 1 then
  M.get_cmds = function(pids)
    return vim.tbl_map(function(pid)
      return { "taskkill", "/pid", pid, "/F" }
    end, pids)
  end
else
  M.get_cmds = function(pids)
    local cmd = { "kill" }
    vim.list_extend(cmd, pids)
    return { cmd }
  end
end

function M.action_kill(items)
  local pids = vim.tbl_map(function(item)
    return item.pid
  end, items)

  local cmds = M.get_cmds(pids)
  return require("thetto2.vendor.promise").all_settled(vim.tbl_map(function(cmd)
    return require("thetto2.util.job").promise(cmd)
  end, cmds))
end

return M
