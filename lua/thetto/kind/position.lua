local M = {}

M.action_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_tab_open = function(items)
  local bufnr = vim.api.nvim_get_current_buf()
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. bufnr)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_default = M.action_open

return M
