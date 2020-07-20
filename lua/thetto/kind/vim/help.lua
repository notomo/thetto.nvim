local M = {}

M.action_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("help " .. item.value)
    vim.api.nvim_command("only")
  end
end

M.action_tab_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tab help " .. item.value)
  end
end

M.action_vsplit_open = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vertical help " .. item.value)
  end
end

M.action_default = M.action_open

return M
