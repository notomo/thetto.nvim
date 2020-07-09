local M = {}

M.action_execute = function(candidates)
  for _, candidate in ipairs(candidates) do
    vim.api.nvim_command("Thetto " .. candidate.source_name)
  end
end

M.action_default = M.action_execute

return M
