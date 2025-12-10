local pathlib = require("thetto.lib.path")

local M = {}

function M._to_item(cwd)
  return function(v)
    local path = vim.uri_to_fname(v.uri)
    local relative_path = pathlib.to_relative(path, cwd)
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
    local bufnr = source_ctx.bufnr
    local method = "textDocument/implementation"
    local cancel = require("thetto.util.lsp").request({
      bufnr = bufnr,
      method = method,
      clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = method,
      }),
      params = function(client)
        return vim.lsp.util.make_position_params(source_ctx.window_id, client.offset_encoding)
      end,
      observer = {
        next = function(result)
          local items = vim
            .iter(result or {})
            :map(function(e)
              return to_item(e)
            end)
            :totable()
          observer:next(items)
        end,
        complete = function()
          observer:complete()
        end,
        error = function(err)
          observer:error(err)
        end,
      },
    })
    return cancel
  end
end

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

return M
