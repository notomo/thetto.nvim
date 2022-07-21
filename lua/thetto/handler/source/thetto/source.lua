local M = {}

function M.collect()
  local items = {}
  for _, e in ipairs(require("thetto.core.items.source").all()) do
    table.insert(items, { value = e.name, path = e.path })
  end
  return items
end

M.kind_name = "thetto/source"

return M
