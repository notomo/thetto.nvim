local M = {}

function M.action_delete(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_set_hl(0, item.value, {})
  end
end

return M
