local M = {}

function M.action_echo(items)
  for _, item in ipairs(items) do
    vim.api.nvim_out_write(item.value .. "\n")
  end
end

M.default_action = "echo"

return M
