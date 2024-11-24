local M = {}

function M.range(range)
  if not range then
    return nil
  end
  return {
    s = { row = range.start.line, column = range.start.character },
    e = { row = range["end"].line, column = range["end"].character },
  }
end

--- @class ThettoLspRequestContext
--- @field method string
--- @field clients vim.lsp.Client[]
--- @field bufnr integer
--- @field observer Observer
--- @field params fun(vim.lsp.client):table

--- @param req_cxt ThettoLspRequestContext
function M.request(req_cxt)
  local subscriber = function(observer)
    local client_count = #req_cxt.clients
    if client_count == 0 then
      observer:complete()
      return
    end

    local completed = {}
    local complete = function(client_id)
      completed[client_id] = true
      if vim.tbl_count(completed) ~= client_count then
        return
      end
      observer:complete()
    end

    local request = function(client)
      local params = req_cxt.params(client)
      local _, request_id = client:request(req_cxt.method, params, function(err, result, ctx)
        if err then
          observer:error(err)
          return
        end

        if not result then
          complete(client.id)
          return
        end

        observer:next(result, ctx)
        complete(client.id)
      end, req_cxt.bufnr)

      local cancel = function()
        client:cancel_request(request_id)
      end
      return cancel
    end

    local cancels = vim.iter(req_cxt.clients):map(request):totable()
    local cancel = function()
      for _, f in ipairs(cancels) do
        f()
      end
    end
    return cancel
  end

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  local subscription = observable:subscribe(req_cxt.observer)
  return function()
    subscription:unsubscribe()
  end
end

return M
