local pathlib = require("thetto.lib.path")
local vim = vim

local M = {}

M.opts = {
  cwd_marker = "%s/",
}

function M.collect(source_ctx)
  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local dir = vim.fs.basename(source_ctx.cwd)
  local cwd_marker = source_ctx.opts.cwd_marker:format(dir)
  local home = pathlib.home()

  return vim
    .iter(require("thetto.core.store").get_data("file/mru"))
    :map(function(path)
      local relative_path = to_relative(path)
      local value = relative_path:gsub(home, "~")
      if path ~= relative_path then
        value = cwd_marker .. relative_path
      end
      return {
        value = value,
        path = path,
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
