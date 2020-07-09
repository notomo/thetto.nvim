local M = {}

M.action_open = function(candidates)
  for _, candidate in ipairs(candidates) do
    vim.api.nvim_win_set_cursor(0, {candidate.row, 0})
  end
end

M.action_default = M.action_open

return M
