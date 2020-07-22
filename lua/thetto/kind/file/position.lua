local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("edit" .. item.path)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit " .. item.path)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("edit " .. item.path)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.default_action = "open"

return M
