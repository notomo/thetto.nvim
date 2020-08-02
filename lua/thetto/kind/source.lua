local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("Thetto " .. item.value)
  end
end

M.default_action = "execute"

return M
