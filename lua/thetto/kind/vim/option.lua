local M = {}

M.action_toggle = function(_, items)
  for _, item in ipairs(items) do
    local name = item.option.name
    local info = vim.api.nvim_get_option_info(name)
    if info.type == "boolean" then
      vim.cmd(("setlocal %s!"):format(name))
    end
  end
end

M.default_action = "toggle"

return M
