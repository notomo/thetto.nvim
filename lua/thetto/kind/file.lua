local M = {}

M.action_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("edit " .. item.path)
  end
end

M.action_tab_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit " .. item.path)
  end
end

M.action_default = M.action_open

return M
