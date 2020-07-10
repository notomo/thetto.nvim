local M = {}

M.action_open = function(candidates)
  for _, candidate in ipairs(candidates) do
    vim.api.nvim_command("help " .. candidate.value)
    vim.api.nvim_command("only")
  end
end

M.action_default = M.action_open

return M
