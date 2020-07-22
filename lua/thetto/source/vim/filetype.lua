local M = {}

M.collect = function()
  local items = {}
  local names = vim.fn.getcompletion("*", "filetype")
  for _, name in ipairs(names) do
    table.insert(items, {value = name})
  end
  return items
end

M.kind_name = "word"

return M
