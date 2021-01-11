local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("Thetto " .. item.value)
  end
end

M.default_action = "execute"

return M
