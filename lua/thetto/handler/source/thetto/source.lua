local Source = require("thetto.core.source").Source

local M = {}

function M.collect()
  local items = {}
  for _, name in ipairs(Source.all_names()) do
    table.insert(items, {value = name})
  end
  return items
end

M.kind_name = "thetto/source"

return M
