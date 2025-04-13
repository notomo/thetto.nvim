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
--- @field server_capabilities string[]?

--- @param req_ctx ThettoLspRequestContext
function M.request(req_ctx)
  local subscriber = function(observer)
    local client_count = #req_ctx.clients
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
      if req_ctx.server_capabilities and vim.tbl_get(client.server_capabilities, req_ctx.server_capabilities) then
        complete(client.id)
        return
      end

      local params = req_ctx.params(client)
      local finished = false
      local _, request_id = client:request(req_ctx.method, params, function(err, result, ctx)
        finished = true

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
      end, req_ctx.bufnr)

      local cancel = function()
        if not finished and request_id then
          client:cancel_request(request_id)
        end
      end
      return cancel
    end

    local cancels = vim.iter(req_ctx.clients):map(request):totable()
    local cancel = function()
      for _, f in ipairs(cancels) do
        f()
      end
    end
    return cancel
  end

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  local subscription = observable:subscribe(req_ctx.observer)
  return function()
    subscription:unsubscribe()
  end
end

return M
