local M = {}

function M.collect(_, source_ctx)
  local paths = {}
  for _, path in ipairs(vim.fn.readdir(source_ctx.cwd)) do
    local abs_path = vim.fn.fnamemodify(source_ctx.cwd .. "/" .. path, ":p:gs?\\?\\/?")
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
      kind_name = "file/directory"
    else
      value = vim.fn.fnamemodify(path, ":t")
    end
    table.insert(items, { value = value, path = path, kind_name = kind_name })
  end
  return items
end

vim.cmd("highlight default link ThettoFileInDirDirectory String")

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  highlighter:filter("ThettoFileInDirDirectory", first_line, items, function(item)
    return item.kind_name == "file/directory"
  end)
end

M.kind_name = "file"

return M
