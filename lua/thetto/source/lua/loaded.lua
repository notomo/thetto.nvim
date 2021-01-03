local M = {}

M.collect = function()
  local items = {}
  for key in pairs(package.loaded) do
    table.insert(items, {value = key})
  end
  return items
end

M.kind_name = "lua/package"

return M
