local M = {}

function M.action_toggle(items)
  vim.iter(items):each(function(item)
    local name = item.option.name
    local info = vim.api.nvim_get_option_info2(name, {})
    if info.type == "boolean" then
      vim.cmd.setlocal(name .. "!")
      return
    end

    local prompt = ("setlocal %s="):format(name)
    local value = vim.fn.input(prompt, item.option.value) ---@type string|number
    if value == "" then
      return
    end
    if info.type == "number" then
      value = assert(tonumber(value))
    end
    vim.opt_local[name] = value
  end)
end

M.default_action = "toggle"

return M
