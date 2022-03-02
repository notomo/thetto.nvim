local pathlib = require("thetto.lib.path")

local M = {}

function M.collect()
  local items = {}
  local home = pathlib.home()
  local paths = vim.api.nvim_list_runtime_paths()
  for _, path in ipairs(paths) do
    local value = path:gsub(home, "~")
    table.insert(items, { value = value, path = path })
  end
  return items
end

M.kind_name = "file/directory"

return M
