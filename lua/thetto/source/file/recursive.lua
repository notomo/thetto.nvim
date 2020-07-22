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
    if vim.fn.isdirectory(abs_path) == 1 then
      local dir_entries = collect(dir_abs_path .. name)
      vim.list_extend(paths, dir_entries)
    else
      table.insert(paths, abs_path)
    end

    ::continue::
  end
  return paths
end

M.collect = function(_, opts)
  local paths = collect(opts.cwd)
  local home = os.getenv("HOME")
  local items = {}
  for _, path in ipairs(paths) do
    local value = path:gsub("^" .. opts.cwd .. "/", ""):gsub(home, "~")
    table.insert(items, {value = value, path = path})
  end
  return items
end

M.kind_name = "file"

return M
