local M = {}

function M.action_delete_group(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_clear_autocmds({ group = item.autocmd.group })
  end
end

function M.action_delete_autocmd_by_pattern(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_clear_autocmds({
      group = item.autocmd.group,
      event = item.autocmd.event,
      pattern = item.autocmd.pattern,
    })
  end
end

function M.action_delete_autocmd_by_event(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_clear_autocmds({
      group = item.autocmd.group,
      event = item.autocmd.event,
    })
  end
end

return M
