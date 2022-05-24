local pathlib = require("thetto.lib.path")
local listlib = require("thetto.lib.list")
local filelib = require("thetto.lib.file")

local M = {}

M.opts = { file_path = nil, default_paths = {} }

function M.collect(self)
  local file_path = self.opts.file_path or pathlib.user_data_path("file_bookmark.txt")
  if filelib.create_if_need(file_path) then
    io.open(file_path, "w"):close()
  end

  local f = io.open(file_path, "r")
  local lines = { file_path }
  vim.list_extend(lines, self.opts.default_paths)
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  lines = listlib.unique(lines)

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
    table.insert(items, { value = path, path = path, kind_name = kind_name })
  end

  return items
end

vim.cmd("highlight default link ThettoFileBookmarkDirectory String")

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoFileBookmarkDirectory",
    filter = function(item)
      return item.kind_name == "file/directory"
    end,
  },
})

M.kind_name = "file"

return M
