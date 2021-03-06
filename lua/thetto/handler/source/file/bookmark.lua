local M = {}

M.opts = {file_path = nil, default_paths = {}}

function M.collect(self)
  local file_path = self.opts.file_path or self.pathlib.user_data_path("file_bookmark.txt")
  if self.filelib.create_if_need(file_path) then
    local f = io.open(file_path, "w")
    for _, path in ipairs(self.opts.default_paths) do
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
      kind_name = "file/directory"
    end
    table.insert(items, {value = path, path = path, kind_name = kind_name})
  end

  return items
end

vim.cmd("highlight default link ThettoFileBookmarkDirectory String")

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  highlighter:filter("ThettoFileBookmarkDirectory", first_line, items, function(item)
    return item.kind_name == "file/directory"
  end)
end

M.kind_name = "file"

return M
