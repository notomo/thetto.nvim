local M = {}

function M.collect()
  local items = {}
  local all_sources, err = require("thetto.core.items.source").all()
  if err then
    return nil, err
  end
  for _, e in ipairs(all_sources) do
    table.insert(items, { value = e.name, path = e.path })
  end
  return items
end

M.kind_name = "thetto/source"

return M
