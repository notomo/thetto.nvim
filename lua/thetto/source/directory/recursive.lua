local M = {}

M.ignore_files = {".git", "node_modules", ".mypy_cache", "__pycache__", ".DS_Store"}

local function collect(path, depth, min_depth, max_depth)
  local paths = {}
  local dir_abs_path = vim.fn.fnamemodify(path, ":p")
  for _, name in ipairs(vim.fn.readdir(dir_abs_path)) do
    for _, ignore in ipairs(M.ignore_files) do
      if name == ignore then
        goto continue
      end
    end

    local abs_path = dir_abs_path .. name
    if vim.fn.isdirectory(abs_path) ~= 1 then
      goto continue
    end

    if min_depth <= depth and depth <= max_depth then
      table.insert(paths, abs_path)
    end
    if depth < max_depth then
      local dir_entries = collect(dir_abs_path .. name, depth + 1, min_depth, max_depth)
      vim.list_extend(paths, dir_entries)
    end

    ::continue::
  end
  return paths
end

M.opts = {min_depth = 1, max_depth = 10000}

M.collect = function(self, opts)
  local paths = collect(opts.cwd, 1, self.opts.min_depth, self.opts.max_depth)
  local home = os.getenv("HOME")
  local items = {}
  for _, path in ipairs(paths) do
    local value = (path .. "/"):gsub("^" .. opts.cwd .. "/", ""):gsub(home, "~")
    table.insert(items, {value = value, path = path})
  end
  return items
end

M.kind_name = "directory"

return M
