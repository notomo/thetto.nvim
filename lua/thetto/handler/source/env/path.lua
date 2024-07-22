local pathlib = require("thetto.lib.path")

local M = {}

M.opts = { key = "PATH" }

function M.collect(source_ctx)
  return vim
    .iter(vim.split(os.getenv(source_ctx.opts.key), pathlib.env_separator, { plain = true }))
    :map(function(path)
      if vim.fn.isdirectory(path) == 0 then
        return nil
      end
      return {
        value = path,
        path = path,
      }
    end)
    :totable()
end

M.kind_name = "file/directory"

return M
