local M = {}

M.action_delete_group = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("autocmd! " .. item.autocmd.group)
  end
end

return setmetatable(M, require("thetto/kind/file"))
