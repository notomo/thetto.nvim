local highlight = require("thetto/highlight")

local M = {}

M.make = function(opts)
  local paths = {}
  for _, path in ipairs(vim.fn.readdir(opts.cwd)) do
    local abs_path = vim.fn.fnamemodify(opts.cwd .. "/" .. path, ":p:gs?\\?\\/?")
    table.insert(paths, abs_path)
  end

  paths = vim.fn.sort(paths, function(a, b)
    return vim.fn.isdirectory(b) - vim.fn.isdirectory(a)
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

M.highlight = function(bufnr, items)
  local ns = highlight.reset(bufnr)
  highlight.kind(bufnr, items, ns, "directory", "String")
end

M.kind_name = "file"

return M
