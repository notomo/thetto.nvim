local highlight = require("thetto/highlight")

local M = {}

M.ignore_files = {".git", "node_modules", ".mypy_cache", "__pycache__", ".DS_Store"}

local function collect(path)
  local paths = {}
  local dir_abs_path = vim.fn.fnamemodify(path, ":p")
  for _, name in ipairs(vim.fn.readdir(dir_abs_path)) do
    for _, ignore in ipairs(M.ignore_files) do
      if name == ignore then
        goto continue
      end
    end

    local abs_path = dir_abs_path .. name
    table.insert(paths, abs_path)
    if vim.fn.isdirectory(abs_path) == 1 then
      local dir_entries = collect(dir_abs_path .. name)
      vim.list_extend(paths, dir_entries)
    end
    ::continue::
  end
  return paths
end

M.make = function(opts)
  local paths = collect(opts.cwd)
  local home = os.getenv("HOME")
  local items = {}
  for _, path in ipairs(paths) do
    local value = path
    local kind_name = M.kind_name
    if vim.fn.isdirectory(path) ~= 0 then
      value = value .. "/"
      kind_name = "directory"
    end
    local desc = value:gsub("^" .. opts.cwd .. "/", "")
    desc = desc:gsub(home, "~")
    table.insert(items, {desc = desc, value = value, path = path, kind_name = kind_name})
  end
  return items
end

M.highlight = function(bufnr, items)
  local ns = highlight.reset(bufnr)
  highlight.kind(bufnr, items, ns, "directory", "String")
end

M.kind_name = "file"

return M
