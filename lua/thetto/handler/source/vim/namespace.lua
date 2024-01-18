local M = {}

function M.collect()
  local items = {}
  local namespaces = vim.api.nvim_get_namespaces()
  for name, id in pairs(namespaces) do
    local value = ("%2d: %s"):format(id, name)
    table.insert(items, { value = value, namespace = id })
  end
  return items
end

M.kind_name = "word"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_by_name("namespace"),
})

return M
