local pathlib = require("thetto.lib.path")
local listlib = require("thetto.lib.list")
local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  file_path = nil,
  default_paths = {},
}

function M.collect(source_ctx)
  local file_path = source_ctx.opts.file_path or pathlib.user_data_path("file_bookmark.txt")
  if filelib.create_if_need(file_path) then
    io.open(file_path, "w"):close()
  end

  local f = io.open(file_path, "r")
  local lines = { file_path }
  vim.list_extend(lines, source_ctx.opts.default_paths)
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  lines = listlib.unique(lines)

  return vim
    .iter(lines)
    :map(function(line)
      return vim.fn.glob(line, true, true, true)
    end)
    :flatten()
    :map(function(path)
      local kind_name = M.kind_name
      if vim.fn.isdirectory(path) ~= 0 then
        kind_name = "file/directory"
      end
      return {
        value = path,
        path = path,
        kind_name = kind_name,
      }
    end)
    :totable()
end

vim.api.nvim_set_hl(0, "ThettoFileBookmarkDirectory", { default = true, link = "String" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoFileBookmarkDirectory",
    filter = function(item)
      return item.kind_name == "file/directory"
    end,
  },
})

M.kind_name = "file"

return M
