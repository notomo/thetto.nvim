local M = {}

M.make = function()
  local items = {}
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/source/*.lua", true)
  for _, path in ipairs(paths) do
    local source_file = vim.split(path, "lua/thetto/source/", true)[2]
    local name = source_file:sub(1, #source_file - 4)
    table.insert(items, {value = name, path = path, source_name = name})
  end
  return items
end

M.kind_name = "source"

return M
