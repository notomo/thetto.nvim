local M = {}

M.file_path = nil
M.default_paths = {}

function M.collect(self)
  local file_path = M.file_path or self.pathlib.user_data_path("file_bookmark.txt")
  if self.filelib.create_if_need(file_path) then
    local f = io.open(file_path, "w")
    for _, path in ipairs(M.default_paths) do
      f:write(path .. "\n")
    end
    f:close()
  end

  local f = io.open(file_path, "r")
  local lines = {file_path}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  lines = self.listlib.unique(lines)

  local paths = {}
  for _, line in ipairs(lines) do
    vim.list_extend(paths, vim.fn.glob(line, true, true, true))
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

vim.cmd("highlight default link ThettoFileBookmarkDirectory String")

function M.highlight(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("ThettoFileBookmarkDirectory", items, function(item)
    return item.kind_name == "directory"
  end)
end

M.kind_name = "file"

return M
