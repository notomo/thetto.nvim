local M = {}

function M.collect(source_ctx)
  return function(observer)
    local bufnr = source_ctx.bufnr
    local method = "textDocument/codeLens"
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
        next = function(result, ctx)
          vim.lsp.codelens.on_codelens(nil, result, ctx)

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

M.kind_name = "vim/position"

M.cwd = require("thetto.util.cwd").project()

return M
