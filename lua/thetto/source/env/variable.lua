local M = {}

M.collect = function(self)
  local names = vim.fn.getcompletion("*", "environment")
  local items = {}
  for _, name in ipairs(names) do
    local value = ("%s=%s"):format(name, os.getenv(name))
    table.insert(items, {value = value})
  end
  return items
end

M.kind_name = "word"

return M
