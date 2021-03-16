local M = {}

M.collect = function()
  local items = {}
  -- NOTE: ignore 'all'
  local names = {unpack(vim.fn.getcompletion("*", "option"), 2)}
  for _, name in ipairs(names) do
    local cmd = ("echo &%s"):format(name)
    local option_value = vim.api.nvim_exec(cmd, true)
    local value = ("%s=%s"):format(name, option_value)
    table.insert(items, {value = value, option = {name = name, value = option_value}})
  end
  return items
end

M.kind_name = "vim/option"

return M
