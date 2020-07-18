local M = {}

M.make = function()
  local paths = vim.fn.readdir(".")
  paths = vim.fn.sort(paths, function(a, b)
    return vim.fn.isdirectory(b) - vim.fn.isdirectory(a)
  end)

  local items = {}
  for _, path in ipairs(paths) do
    local abs_path = vim.fn.fnamemodify(path, ":p:gs?\\?\\/?")
    local value = path
    local kind_name = M.kind_name
    if vim.fn.isdirectory(abs_path) ~= 0 then
      value = value .. "/"
      kind_name = "directory"
    end
    table.insert(items, {value = value, path = abs_path, kind_name = kind_name})
  end
  return items
end

M.kind_name = "file"

return M
