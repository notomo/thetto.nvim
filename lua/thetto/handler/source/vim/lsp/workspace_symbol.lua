local pathlib = require("thetto.lib.path")

local M = {}

function M._to_item(cwd)
  local to_relative = pathlib.relative_modifier(cwd)
  return function(v)
    local kind = vim.lsp.protocol.SymbolKind[v.kind]
    local path = vim.uri_to_fname(v.location.uri)
    local relative_path = to_relative(path)
    local row = v.location.range.start.line + 1
    local path_row = ("%s:%d"):format(relative_path, row)
    local desc = ("%s %s [%s]"):format(path_row, v.name, kind)
    return {
      path = path,
      row = row,
      end_row = v.location.range["end"].line,
      column = v.location.range.start.character,
      end_column = v.location.range["end"].character,
      desc = desc,
      value = v.name,
      kind = kind,
      column_offsets = {
        ["path:relative"] = 0,
        value = #path_row + 1,
        kind = #desc - #kind - 2,
      },
    }
  end
end

function M.collect(source_ctx)
  local to_item = M._to_item(source_ctx.cwd)
  return function(observer)
    local method = "workspace/symbol"
    local params = { query = source_ctx.pattern or "" }
    local _, cancel = vim.lsp.buf_request(source_ctx.bufnr, method, params, function(_, result)
      local items = vim
        .iter(result or {})
        :map(function(e)
          return to_item(e)
        end)
        :totable()
      observer:next(items)
      observer:complete()
    end)
    return cancel
  end
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
  {
    group = "Statement",
    start_key = "kind",
  },
})

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

return M
