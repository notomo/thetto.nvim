local pathlib = require("thetto.lib.path")

local M = {}

function M._prepare(bufnr, window_id)
  local promise, resolve, reject = require("thetto.vendor.promise").with_resolvers()
  local method = "textDocument/prepareCallHierarchy"
  local results = {}
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
        resolve(results)
      end,
      error = function(err)
        reject(err)
      end,
    },
  })
  return promise, cancel
end

function M._call_hierarchy(bufnr, client_id, call_hierarchy_item, method)
  local promise, resolve, reject = require("thetto.vendor.promise").with_resolvers()
  local results = {}
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
        resolve(results)
      end,
      error = function(err)
        reject(err)
      end,
    },
  })
  return promise, cancel
end

function M.request(bufnr, window_id, method)
  local prepare_promise, prepare_cancel = M._prepare(bufnr, window_id)
  local cancels = { prepare_cancel }
  local promise = prepare_promise:next(function(results)
    local promises = vim
      .iter(results)
      :map(function(x)
        local call_hierarchy_item = x.result[1]
        local client_id = x.ctx.client_id
        local promise, cancel = M._call_hierarchy(bufnr, client_id, call_hierarchy_item, method)
        table.insert(cancels, cancel)
        return promise
      end)
      :totable()
    return require("thetto.vendor.promise").all(promises)
  end)
  return promise, cancels
end

function M.collect(source_ctx)
  return function(observer)
    local path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
    local relative_path = pathlib.to_relative(path, source_ctx.cwd)

    local promise, cancels = M.request(source_ctx.bufnr, source_ctx.window_id, "callHierarchy/outgoingCalls")

    promise
      :next(function(results)
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
