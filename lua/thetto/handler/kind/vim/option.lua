local M = {}

function M.action_toggle(_, items)
  for _, item in ipairs(items) do
    local name = item.option.name
    local info = vim.api.nvim_get_option_info(name)
    if info.type == "boolean" then
      vim.cmd.setlocal(name .. "!")
    else
      local prompt = ("setlocal %s="):format(name)
      local value = vim.fn.input(prompt, item.option.value)
      if value == "" then
        return
      end
      vim.opt_local[name] = value
      return
    end
  end
end

M.default_action = "toggle"

return M
