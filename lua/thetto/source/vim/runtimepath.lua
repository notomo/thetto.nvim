local M = {}

M.collect = function()
  local items = {}
  local home = os.getenv("HOME")
  local paths = vim.api.nvim_list_runtime_paths()
  for _, path in ipairs(paths) do
    local value = path:gsub(home, "~")
    table.insert(items, {value = value, path = path})
  end
  return items
end

M.kind_name = "directory"

return M
