local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command(item.value)
  end
end

M.default_action = "execute"

return M
