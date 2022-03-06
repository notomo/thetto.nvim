local M = {}

function M.collect()
  local items = {}
  for _, name in ipairs(require("thetto.core.items.source").all_names()) do
    table.insert(items, { value = name })
  end
  return items
end

M.kind_name = "thetto/source"

return M
