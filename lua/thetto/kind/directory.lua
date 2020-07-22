local M = {}

M.after = function(_)
end

M.action_cd = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_set_current_dir(item.path)
    M.after(item.path)
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_set_current_dir(item.path)
    M.after(item.path)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_set_current_dir(item.path)
    M.after(item.path)
  end
end

M.action_default = M.action_cd
M.action_open = M.action_cd

return M
