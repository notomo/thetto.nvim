local M = {}

function M.action_delete_group(_, items)
  for _, item in ipairs(items) do
    vim.cmd("autocmd! " .. item.autocmd.group)
  end
end

function M.action_delete_autocmd_by_pattern(_, items)
  for _, item in ipairs(items) do
    vim.cmd(("autocmd! %s %s %s"):format(item.autocmd.group, item.autocmd.event, item.autocmd.pattern))
  end
end

function M.action_delete_autocmd_by_event(_, items)
  for _, item in ipairs(items) do
    vim.cmd(("autocmd! %s %s"):format(item.autocmd.group, item.autocmd.event))
  end
end

return M
