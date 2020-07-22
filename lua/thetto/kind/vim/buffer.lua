local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.default_action = "open"

return M
