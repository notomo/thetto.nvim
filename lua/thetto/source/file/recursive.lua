local highlight = require("thetto/highlight")

local M = {}

local function collect(path)
  local paths = {}
  local dir_abs_path = vim.fn.fnamemodify(path, ":p")
  for _, name in ipairs(vim.fn.readdir(dir_abs_path)) do
    local abs_path = dir_abs_path .. name
    table.insert(paths, abs_path)
    if vim.fn.isdirectory(abs_path) == 1 then
      local dir_entries = collect(dir_abs_path .. name)
      vim.list_extend(paths, dir_entries)
    end
  end
  return paths
end

M.make = function()
  local paths = collect(".")
  local home = os.getenv("HOME")
  local items = {}
  for _, path in ipairs(paths) do
    local value = path
    local kind_name = M.kind_name
    if vim.fn.isdirectory(path) ~= 0 then
      value = value .. "/"
      kind_name = "directory"
    end
    local desc = path:gsub(home, "~")
    table.insert(items, {desc = desc, value = value, path = path, kind_name = kind_name})
  end
  return items
end

M.highlight = function(bufnr, items)
  highlight.kind(bufnr, items, "directory", "String")
end

M.kind_name = "file"

return M
