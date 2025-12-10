local pathlib = require("thetto.lib.path")

local M = {}

function M.collect(source_ctx)
  return function(observer)
    local promise, cancels = require("thetto.handler.source.vim.lsp.outgoing_calls").request(
      source_ctx.bufnr,
      source_ctx.window_id,
      "callHierarchy/incomingCalls"
    )

    promise
      :next(function(results)
        local items = vim
          .iter(results)
          :map(function(result)
            vim
              .iter(result or {})
              :map(function(call)
                local call_hierarchy = call["from"]
                return vim
                  .iter(call.fromRanges)
                  :map(function(range)
                    local path = vim.uri_to_fname(call_hierarchy.uri)
                    local relative_path = pathlib.to_relative(path, source_ctx.cwd)
                    local row = range.start.line + 1
                    local value = call_hierarchy.name
                    local path_with_row = ("%s:%d"):format(relative_path, row)
                    return {
                      path = path,
                      desc = ("%s %s()"):format(path_with_row, call_hierarchy.name),
                      value = value,
                      row = row,
                      end_row = range["end"].line,
                      column = range.start.character,
                      end_column = range["end"].character,
                      column_offsets = {
                        ["path:relative"] = 0,
                        value = #path_with_row + 1,
                      },
                    }
                  end)
                  :totable()
              end)
              :flatten()
              :totable()
          end)
          :flatten()
          :totable()
        observer:next(items)
        observer:complete()
      end)
      :catch(function(err)
        observer:error(err)
      end)

    local cancel = function()
      for _, f in ipairs(cancels) do
        f()
      end
    end
    return cancel
  end
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
})

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_by_name("row"),
})

return M
