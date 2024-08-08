local M = {}

local cursor_lib = require("thetto.lib.cursor")

function M.get_cursor_word(window_id)
  return cursor_lib.word(window_id, [=[[^[:space:]/]*]=])
end

function M.collect(source_ctx)
  local cursor_word = cursor_lib.word(source_ctx.window_id, [=[\.?/[^[:space:]]*]=])
  if not cursor_word then
    return {}
  end

  local dir_path = vim.fs.dirname(cursor_word.str)
  return vim
    .iter(vim.fs.dir(dir_path))
    :map(function(name, typ)
      local full_path = vim.fs.joinpath(dir_path, name)
      return {
        value = name,
        path = full_path,
        kind_name = typ == "directory" and "file/directory" or "file",
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
