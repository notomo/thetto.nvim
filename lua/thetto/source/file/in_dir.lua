local M = {}

M.collect = function(_, opts)
  local paths = {}
  for _, path in ipairs(vim.fn.readdir(opts.cwd)) do
    local abs_path = vim.fn.fnamemodify(opts.cwd .. "/" .. path, ":p:gs?\\?\\/?")
    table.insert(paths, abs_path)
  end

  table.sort(paths, function(a, b)
    local is_dir_a = vim.fn.isdirectory(a)
    local is_dir_b = vim.fn.isdirectory(b)
    if is_dir_a ~= is_dir_b then
      return is_dir_a > is_dir_b
    end
    return a < b
  end)

  local items = {}
  for _, path in ipairs(paths) do
    local value
    local kind_name = M.kind_name
    if vim.fn.isdirectory(path) ~= 0 then
      value = vim.fn.fnamemodify(path, ":h:t") .. "/"
      kind_name = "directory"
    else
      value = vim.fn.fnamemodify(path, ":t")
    end
    table.insert(items, {value = value, path = path, kind_name = kind_name})
  end
  return items
end

vim.api.nvim_command("highlight default link ThettoFileInDirDirectory String")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("ThettoFileInDirDirectory", items, function(item)
    return item.kind_name == "directory"
  end)
end

M.kind_name = "file"

return M
