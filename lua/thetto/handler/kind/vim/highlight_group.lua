local M = {}

function M.action_delete(_, items)
  for _, item in ipairs(items) do
    vim.cmd("highlight clear " .. item.value)
    vim.cmd(("highlight! link %s NONE"):format(item.value))
  end
end

return M
