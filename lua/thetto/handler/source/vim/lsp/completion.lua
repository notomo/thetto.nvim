local M = {}

-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItemKind
local completionItemKind = {
  [1] = "Text",
  [2] = "Method",
  [3] = "Function",
  [4] = "Constructor",
  [5] = "Field",
  [6] = "Variable",
  [7] = "Class",
  [8] = "Interface",
  [9] = "Module",
  [10] = "Property",
  [11] = "Unit",
  [12] = "Value",
  [13] = "Enum",
  [14] = "Keyword",
  [15] = "Snippet",
  [16] = "Color",
  [17] = "File",
  [18] = "Reference",
  [19] = "Folder",
  [20] = "EnumMember",
  [21] = "Constant",
  [22] = "Struct",
  [23] = "Event",
  [24] = "Operator",
  [25] = "TypeParameter",
}

function M.collect(source_ctx)
  return function(observer)
    local method = vim.lsp.protocol.Methods.textDocument_completion
    local clients = vim.lsp.get_clients({
      bufnr = source_ctx.bufnr,
      method = method,
    })
    if vim.tbl_isempty(clients) then
      observer:next({})
      observer:complete()
      return
    end

    local completed = {}
    local complete = function(client_id)
      completed[client_id] = true
      if vim.tbl_count(completed) ~= #clients then
        return
      end
      observer:complete()
    end

    local params = vim.lsp.util.make_position_params(source_ctx.window_id)
    local request = function(client)
      local _, request_id = client.request(method, params, function(_, result)
        if not result then
          observer:next({})
          complete(client.id)
          return
        end

        local items = vim
          .iter(result.items)
          :map(function(item)
            return {
              value = item.insertText or item.label,
              kind_label = completionItemKind[item.kind],
            }
          end)
          :filter(function(item)
            return item.kind_label ~= "Snippet"
          end)
          :totable()
        observer:next(items)
        complete(client.id)
      end, source_ctx.bufnr)

      local cancel = function()
        client.cancel_request(request_id)
      end
      return cancel
    end

    local cancels = vim.iter(clients):map(request):totable()

    local cancel = function()
      for _, f in ipairs(cancels) do
        f()
      end
    end
    return cancel
  end
end

M.kind_name = "word"

M.cwd = require("thetto.util.cwd").project()

return M
