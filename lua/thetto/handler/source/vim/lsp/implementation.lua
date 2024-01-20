local pathlib = require("thetto.lib.path")

local M = {}

function M._to_item(cwd)
  local to_relative = pathlib.relative_modifier(cwd)
  return function(v)
    local path = vim.uri_to_fname(v.uri)
    local relative_path = to_relative(path)
    local row = v.range.start.line + 1
    return {
      value = ("%s:%d"):format(relative_path, row),
      path = path,
      row = row,
      end_row = v.range["end"].line,
      column = v.range.start.character,
      end_column = v.range["end"].character,
      column_offsets = {
        ["path:relative"] = 0,
      },
    }
  end
end

function M.collect(source_ctx)
  local to_item = M._to_item(source_ctx.cwd)
  return function(observer)
    local method = "textDocument/implementation"
    -- TODO: ctx window
    local params = vim.lsp.util.make_position_params()
    local _, cancel = vim.lsp.buf_request(source_ctx.bufnr, method, params, function(_, result)
      local items = vim.tbl_map(function(e)
        return to_item(e)
      end, result or {})
      observer:next(items)
      observer:complete()
    end)
    return cancel
  end
end

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

return M
