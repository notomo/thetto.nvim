local M = {}

function M.collect(source_ctx)
  local bufnr = source_ctx.bufnr
  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, {
    details = true,
  })
  return vim
    .iter(extmarks)
    :map(function(extmark)
      return {
        value = vim.inspect({
          id = extmark[1],
          row = extmark[2],
          column = extmark[3],
          details = extmark[4],
        }, { indent = "", newline = " " }),
        row = extmark[2] + 1,
        bufnr = bufnr,
      }
    end)
    :totable()
end

M.kind_name = "vim/position"

return M
