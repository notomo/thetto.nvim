local pathlib = require("thetto2.lib.path")

local M = {}

function M.collect(source_ctx)
  return function(observer)
    return require("thetto2.handler.source.vim.lsp.outgoing_calls")
      .request(source_ctx.bufnr, "callHierarchy/incomingCalls")
      :next(function(result)
        local to_relative = pathlib.relative_modifier(source_ctx.cwd)

        local items = {}
        for _, call in pairs(result or {}) do
          local call_hierarchy = call["from"]
          for _, range in pairs(call.fromRanges) do
            local path = vim.uri_to_fname(call_hierarchy.uri)
            local relative_path = to_relative(path)
            local row = range.start.line + 1
            local value = call_hierarchy.name
            local path_with_row = ("%s:%d"):format(relative_path, row)
            table.insert(items, {
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
            })
          end
        end
        observer:next(items)
        observer:complete()
      end)
      :catch(function(err)
        observer:error(err)
      end)
  end
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
})

M.kind_name = "file"

M.cwd = require("thetto2.util.cwd").project()

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").field_by_name("row"),
})

return M
