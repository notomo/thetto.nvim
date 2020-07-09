local M = {}

M.after = function(_)
end

M.action_cd = function(candidates)
  for _, candidate in ipairs(candidates) do
    vim.api.nvim_set_current_dir(candidate.path)
    M.after(candidate.path)
  end
end

M.action_default = M.action_cd

return M
