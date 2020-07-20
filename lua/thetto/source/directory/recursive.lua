local M = {}

M.ignore_files = {".git", "node_modules", ".mypy_cache", "__pycache__"}

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
    if vim.fn.isdirectory(abs_path) == 1 then
      table.insert(paths, abs_path)
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
    local value = path .. "/"
    local desc = value:gsub("^" .. opts.cwd .. "/", "")
    desc = desc:gsub(home, "~")
    table.insert(items, {desc = desc, value = value, path = path})
  end
  return items
end

M.kind_name = "directory"

return M
