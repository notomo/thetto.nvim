local pathlib = require("thetto.lib.path")

local M = {}

--- @async
function M._prepare(bufnr, window_id)
  local method = "textDocument/prepareCallHierarchy"
  local results = {}
  local err = vim.async.await(function(callback)
    local cancel = require("thetto.util.lsp").request({
      bufnr = bufnr,
      method = method,
      clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = method,
      }),
      params = function(client)
        return vim.lsp.util.make_position_params(window_id, client.offset_encoding)
      end,
      observer = {
        next = function(result, ctx)
          table.insert(results, { result = result, ctx = ctx })
        end,
        complete = function()
          callback()
        end,
        error = function(request_err)
          callback(request_err)
        end,
      },
    })
    return require("thetto.lib.async").closable(cancel)
  end)
  if err then
    error(err, 0)
  end
  return results
end

--- @async
function M._call_hierarchy(bufnr, client_id, call_hierarchy_item, method)
  local results = {}
  local err = vim.async.await(function(callback)
    local cancel = require("thetto.util.lsp").request({
      bufnr = bufnr,
      method = method,
      clients = vim.lsp.get_clients({
        id = client_id,
      }),
      params = function(_)
        return { item = call_hierarchy_item }
      end,
      observer = {
        next = function(result)
          table.insert(results, result)
        end,
        complete = function()
          callback()
        end,
        error = function(request_err)
          callback(request_err)
        end,
      },
    })
    return require("thetto.lib.async").closable(cancel)
  end)
  if err then
    error(err, 0)
  end
  return results
end

--- @async
function M.request(bufnr, window_id, method)
  local prepared = M._prepare(bufnr, window_id)

  return require("thetto.lib.async").all(vim
    .iter(prepared)
    :map(function(x)
      local call_hierarchy_item = x.result[1]
      local client_id = x.ctx.client_id
      --- @async
      return function()
        return M._call_hierarchy(bufnr, client_id, call_hierarchy_item, method)
      end
    end)
    :totable())
end

function M.collect(source_ctx)
  return function(observer)
    local path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
    local relative_path = pathlib.to_relative(path, source_ctx.cwd)

    --- @async
    --- @return nil
    local collect = function()
      local results = M.request(source_ctx.bufnr, source_ctx.window_id, "callHierarchy/outgoingCalls")
      local items = vim
        .iter(results)
        :map(function(result)
          vim
            .iter(result or {})
            :map(function(call)
              local call_hierarchy = call["to"]
              return vim
                .iter(call.fromRanges)
                :map(function(range)
                  local row = range.start.line + 1
                  local value = call_hierarchy.name
                  local path_with_row = ("%s:%d"):format(relative_path, row)
                  return {
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
    end

    return require("thetto.lib.async").observe(observer, collect)
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
