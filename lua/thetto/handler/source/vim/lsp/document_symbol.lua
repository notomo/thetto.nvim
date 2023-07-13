local util = require("thetto.util.lsp")

local M = {}

M.opts = {
  ignored_kind = { "variable", "field" },
}

function M.collect(source_ctx)
  local current_path = vim.fn.expand("%:p")
  return function(observer)
    local method = "textDocument/documentSymbol"
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    local _, cancel = vim.lsp.buf_request(source_ctx.bufnr, method, params, function(_, result)
      local items = {}
      for _, v in ipairs(result or {}) do
        vim.list_extend(items, M._to_items(source_ctx, v, "", current_path))
      end
      observer:next(items)
      observer:complete()
    end)
    return cancel
  end
end

function M._to_items(source_ctx, item, parent_key, current_path)
  local kind = vim.lsp.protocol.SymbolKind[item.kind]
  if vim.tbl_contains(source_ctx.opts.ignored_kind, kind:lower()) then
    return {}
  end

  local items = {}

  local range = item.selectionRange or item.location.range
  local name = parent_key .. item.name
  local detail = item.detail or ""
  local desc = ("%s %s [%s]"):format(name, detail:gsub("\n", "\\n"), kind)
  table.insert(items, {
    path = current_path,
    row = range.start.line + 1,
    end_row = range["end"].line + 1,
    column = range.start.character,
    desc = desc,
    value = name,
    kind = kind,
    column_offsets = { value = 0, kind = #desc - #kind - 1 },
    range = util.range(item.selectionRange),
  })

  for _, v in ipairs(item.children or {}) do
    vim.list_extend(items, M._to_items(source_ctx, v, name .. ".", current_path))
  end
  return items
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Statement",
    start_key = "kind",
  },
})

M.kind_name = "file"

M.behaviors = {
  cwd = require("thetto.util.cwd").project(),
}

return M
