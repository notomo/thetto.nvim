local M = {}

function M.collect()
  local items = {}
  local all_kinds, err = require("thetto.core.kind").all()
  if err then
    return nil, err
  end
  for _, e in ipairs(all_kinds) do
    table.insert(items, {
      value = e.name,
      path = e.path,
    })
  end
  return items
end

M.kind_name = "file"

M.sorters = { "length" }

return M
