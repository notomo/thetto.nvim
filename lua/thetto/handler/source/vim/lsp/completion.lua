local M = {}

function M.collect(source_ctx)
  return function(observer)
    local method = vim.lsp.protocol.Methods.textDocument_completion
    local params = vim.lsp.util.make_position_params(source_ctx.window_id)
    local _, cancel = vim.lsp.buf_request(source_ctx.bufnr, method, params, function(_, result)
      if not result then
        observer:next({})
        observer:complete()
        return
      end

      local items = vim
        .iter(result.items)
        :map(function(item)
          return {
            value = item.insertText,
          }
        end)
        :totable()
      observer:next(items)
      observer:complete()
    end)
    return cancel
  end
end

M.kind_name = "word"

M.cwd = require("thetto.util.cwd").project()

return M
