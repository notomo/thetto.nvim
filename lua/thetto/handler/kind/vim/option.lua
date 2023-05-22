local M = {}

function M.action_toggle(items)
  for _, item in ipairs(items) do
    local name = item.option.name
    local info = vim.api.nvim_get_option_info2(name, {})
    if info.type == "boolean" then
      vim.cmd.setlocal(name .. "!")
      goto continue
    end

    local prompt = ("setlocal %s="):format(name)
    local value = vim.fn.input(prompt, item.option.value)
    if value == "" then
      return
    end
    if info.type == "number" then
      value = tonumber(value)
    end
    vim.opt_local[name] = value

    ::continue::
  end
end

M.default_action = "toggle"

return M
