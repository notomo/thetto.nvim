local Context = require("thetto.core.context").Context

local M = {}

function M.collect()
  local items = {}
  for source_name in Context.all() do
    table.insert(items, { value = source_name })
  end
  return items
end

M.kind_name = "thetto/source"
M.default_action = "resume"

return M
