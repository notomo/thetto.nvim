local M = {}

function M.collect(source_ctx)
  return function(observer)
    local method = "textDocument/codeLens"
    local params = { textDocument = vim.lsp.util.make_text_document_params(source_ctx.bufnr) }
    local _, cancel = vim.lsp.buf_request(source_ctx.bufnr, method, params, function(...)
      vim.lsp.codelens.on_codelens(...)

      local items = {}
      for _, codelens in ipairs(vim.lsp.codelens.get(source_ctx.bufnr)) do
        table.insert(items, {
          value = codelens.command.title,
          bufnr = source_ctx.bufnr,
          row = codelens.range.start.line + 1,
          end_row = codelens.range["end"].line,
          column = codelens.range.start.character,
          end_column = codelens.range["end"].character,
        })
      end
      observer:next(items)
      observer:complete()
    end)
    return cancel
  end
end

M.kind_name = "position"

M.cwd = require("thetto.util.cwd").project()

return M
