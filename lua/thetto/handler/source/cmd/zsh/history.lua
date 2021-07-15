local M = {}

function M.collect(_, opts)
  local path = vim.fn.systemlist({"zsh", "-i", "-c", "echo ${HISTFILE}"})[1]
  if not path then
    return {}
  end

  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local lines = vim.fn.reverse(vim.split(f:read("*a"), "\n", true))
  f:close()

  local cmds = vim.tbl_map(function(s)
    return s:gsub(".*;", "")
  end, lines)
  cmds = vim.tbl_filter(function(cmd)
    return cmd ~= ""
  end, cmds)

  return vim.tbl_map(function(cmd)
    return {value = cmd, cwd = opts.cwd, shell = "zsh"}
  end, cmds)
end

M.kind_name = "cmd/shell/cmd"

return M
