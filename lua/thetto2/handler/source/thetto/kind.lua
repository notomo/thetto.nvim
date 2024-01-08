local M = {}

function M.collect()
  local items = {}
  local all_kinds, err = require("thetto2.core.kind").all()
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

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").field_length_by_name("value"),
})

return M
