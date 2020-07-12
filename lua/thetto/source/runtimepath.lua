local M = {}

M.make = function()
  local items = {}
  local paths = vim.api.nvim_list_runtime_paths()
  for _, path in ipairs(paths) do
    table.insert(items, {value = path, path = path})
  end
  return items
end

M.kind_name = "directory"

return M
