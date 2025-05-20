local M = {}

local cursor_lib = require("thetto.lib.cursor")

function M.get_cursor_word(window_id)
  local cursor_path = cursor_lib.word(window_id, [=[(\~|\.)?/[^[:space:]]*]=])
  if not cursor_path then
    return nil
  end
  return cursor_lib.word(window_id, [=[[^[:space:]/]*]=])
end

local labels = {
  file = "File",
  ["file/directory"] = "Directory",
}

function M.collect(source_ctx)
  local cursor_path = cursor_lib.word(source_ctx.window_id, [=[(\~|\.)?/[^[:space:]]*]=])
  if not cursor_path then
    return {}
  end

  local dir_path = vim.fs.dirname(cursor_path.str)
  return vim
    .iter(vim.fs.dir(dir_path))
    :map(function(name, typ)
      local full_path = vim.fs.joinpath(dir_path, name)
      local kind_name = typ == "directory" and "file/directory" or "file"
      return {
        value = name,
        path = full_path,
        kind_name = kind_name,
        kind_label = labels[kind_name],
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
