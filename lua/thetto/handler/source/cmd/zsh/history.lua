local M = {}

function M.collect(source_ctx)
  local path = vim.fn.systemlist({ "zsh", "-i", "-c", "echo ${HISTFILE}" })[1]
  if not path then
    return {}
  end

  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local lines = vim.fn.reverse(vim.split(f:read("*a"), "\n", { plain = true }))
  f:close()

  local cmds = vim
    .iter(lines)
    :map(function(s)
      local x = s:gsub(".*;", "")
      return x
    end)
    :totable()
  cmds = vim
    .iter(cmds)
    :filter(function(cmd)
      return cmd ~= ""
    end)
    :totable()

  return vim
    .iter(cmds)
    :map(function(cmd)
      return { value = cmd, cwd = source_ctx.cwd, shell = "zsh" }
    end)
    :totable()
end

M.kind_name = "cmd/shell/cmd"

return M
