local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    vim.cmd.tabedit()
    vim.fn.termopen({ item.shell }, { cwd = item.cwd })
    vim.fn.chansend(vim.bo.channel, item.value .. "\nexit\n")
  end
  if items[1] then
    vim.cmd.startinsert({ bang = true })
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    vim.cmd.tabedit()
    vim.fn.termopen({ item.shell }, { cwd = item.cwd })
    vim.fn.chansend(vim.bo.channel, item.value .. "\n")
  end
  if items[1] then
    vim.cmd.startinsert({ bang = true })
  end
end

M.default_action = "execute"

return M
