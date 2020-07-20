local M = {}

M.action_execute = function(items)
  for _, item in ipairs(items) do
    if not item.keymap.mode:find("n") then
      goto continue
    end

    local lhs = vim.api.nvim_replace_termcodes(item.keymap.lhs, true, false, true)
    vim.api.nvim_feedkeys(lhs, "mx", true)
    ::continue::
  end
end

M.action_default = M.action_execute

return M
