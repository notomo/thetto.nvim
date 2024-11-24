local M = {}

function M.collect(source_ctx)
  local current_path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
  return function(observer)
    local bufnr = source_ctx.bufnr
    local method = vim.lsp.protocol.Methods.textDocument_documentSymbol
    local cancel = require("thetto.util.lsp").request({
      bufnr = bufnr,
      method = method,
      clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = method,
      }),
      params = function(_)
        return { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
      end,
      observer = {
        next = function(result)
          local items = vim
            .iter(result or {})
            :map(function(v)
              return M._to_items(source_ctx, v, "", current_path)
            end)
            :flatten()
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

function M._to_items(source_ctx, item, parent_key, current_path)
  local symbol_kind = vim.lsp.protocol.SymbolKind[item.kind]

  local items = {}

  local range = item.selectionRange or item.location.range
  local name = parent_key .. item.name
  local detail = item.detail or ""
  local desc = ("%s %s [%s]"):format(name, detail:gsub("\n", "\\n"), symbol_kind)
  table.insert(items, {
    path = current_path,
    row = range.start.line + 1,
    end_row = range["end"].line,
    column = range.start.character,
    end_column = range["end"].character,
    desc = desc,
    value = name,
    symbol_kind = symbol_kind,
    column_offsets = { value = 0, symbol_kind = #desc - #symbol_kind - 1 },
  })

  for _, v in ipairs(item.children or {}) do
    vim.list_extend(items, M._to_items(source_ctx, v, name .. ".", current_path))
  end
  return items
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Statement",
    start_key = "symbol_kind",
  },
})

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

return M
