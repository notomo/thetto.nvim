local M = {}

M.after = function(_)
end

M.action_cd = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("lcd " .. item.path)
    M.after(item.path)
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("lcd " .. item.path)
    M.after(item.path)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("lcd " .. item.path)
    M.after(item.path)
  end
end

M.action_open = M.action_cd
M.action_directory_open = M.action_open
M.action_directory_tab_open = M.action_tab_open

M.default_action = "cd"

return M
