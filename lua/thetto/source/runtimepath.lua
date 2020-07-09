local M = {}

M.make = function()
  local candidates = {}
  local paths = vim.split(vim.o.runtimepath, ",")
  for _, path in ipairs(paths) do
    table.insert(candidates, {value = path, path = path})
  end
  return candidates
end

M.kind_name = "directory"

return M
