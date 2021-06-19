local M = {}

function M.action_delete_group(_, items)
  for _, item in ipairs(items) do
    vim.cmd("autocmd! " .. item.autocmd.group)
  end
end

return M
