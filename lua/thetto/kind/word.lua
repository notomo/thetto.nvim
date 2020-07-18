local M = {}

M.action_echo = function(items)
  for _, item in ipairs(items) do
    vim.api.nvim_out_write(item.value .. "\n")
  end
end

M.action_default = M.action_echo

return M
