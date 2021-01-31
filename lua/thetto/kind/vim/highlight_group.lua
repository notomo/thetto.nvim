local M = {}

M.action_delete = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("highlight clear " .. item.value)
    vim.cmd(("highlight! link %s NONE"):format(item.value))
  end
end

return M
