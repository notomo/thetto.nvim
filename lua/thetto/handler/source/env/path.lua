local pathlib = require("thetto.lib.path")

local M = {}

M.opts = { key = "PATH" }

function M.collect(source_ctx)
  local items = {}
  local paths = vim.split(os.getenv(source_ctx.opts.key), pathlib.env_separator, { plain = true })
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) ~= 0 then
      table.insert(items, { value = path, path = path })
    end
  end
  return items
end

M.kind_name = "file/directory"

return M
