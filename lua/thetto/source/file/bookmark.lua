local util = require("thetto/util")

local M = {}

M.file_path = util.user_data_path("file_bookmark.txt")
M.paths = {}

M.collect = function()
  if util.create_file_if_need(M.file_path) then
    return {}
  end

  local f = io.open(M.file_path, "r")
  local lines = vim.deepcopy(M.paths)
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()

  local paths = {}
  for _, line in ipairs(lines) do
    local path = vim.fn.expand(line)
    if vim.fn.filereadable(path) == 0 and vim.fn.isdirectory(path) == 0 then
      goto continue
    end
    table.insert(paths, path)
    ::continue::
  end

  local items = {}
  for _, path in ipairs(paths) do
    local kind_name = M.kind_name
    if vim.fn.isdirectory(path) ~= 0 then
      kind_name = "directory"
    end
    table.insert(items, {value = path, path = path, kind_name = kind_name})
  end

  return items
end

M.highlight = function(self, bufnr, items)
  local ns = self.highlights.reset(bufnr)
  self.highlights.kind(bufnr, items, ns, "directory", "String")
end

M.kind_name = "file"

return M
