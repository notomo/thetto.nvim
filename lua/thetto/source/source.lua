local sources = require("thetto/core/base_source")

local M = {}

M.collect = function()
  local items = {}
  for _, name in ipairs(sources.names()) do
    table.insert(items, {value = name})
  end
  return items
end

M.kind_name = "source"

return M
