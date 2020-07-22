local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("Thetto " .. item.source_name)
  end
end

M.action_default = M.action_execute

return M
