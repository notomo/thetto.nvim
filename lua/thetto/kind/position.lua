local M = {}

M.go = function(candidates)
  for _, candidate in ipairs(candidates) do
    vim.api.nvim_win_set_cursor(0, {candidate.row, 0})
  end
end

M.default = M.go

return M
