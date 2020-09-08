local M = {}

M.collect = function()
  local items = {}
  local namespaces = vim.api.nvim_get_namespaces()
  for name, id in pairs(namespaces) do
    local value = ("%2d: %s"):format(id, name)
    table.insert(items, {value = value, namespace = id})
  end
  return items
end

M.kind_name = "word"

return M
