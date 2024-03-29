local pathlib = require("thetto.lib.path")

local M = {}

function M.request(bufnr, window_id, method)
  local params = vim.lsp.util.make_position_params(window_id)
  return require("thetto.vendor.promise")
    .new(function(resolve, reject)
      vim.lsp.buf_request(bufnr, "textDocument/prepareCallHierarchy", params, function(err, result, ctx)
        if err then
          return reject(err)
        end

        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then
          return reject(err)
        end
        return resolve(client, result[1])
      end)
    end)
    :next(function(client, call_hierarchy_item)
      return require("thetto.vendor.promise").new(function(resolve, reject)
        client.request(method, { item = call_hierarchy_item }, function(err, result)
          if err then
            return reject(err)
          end
          return resolve(result)
        end, bufnr)
      end)
    end)
end

function M.collect(source_ctx)
  return function(observer)
    return M.request(source_ctx.bufnr, source_ctx.window_id, "callHierarchy/outgoingCalls")
      :next(function(result)
        local to_relative = pathlib.relative_modifier(source_ctx.cwd)
        local path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
        local relative_path = to_relative(path)

        local items = {}
        for _, call in pairs(result or {}) do
          local call_hierarchy = call["to"]
          for _, range in pairs(call.fromRanges) do
            local row = range.start.line + 1
            local value = call_hierarchy.name
            local path_with_row = ("%s:%d"):format(relative_path, row)
            table.insert(items, {
              path = path,
              desc = ("%s %s()"):format(path_with_row, value),
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
