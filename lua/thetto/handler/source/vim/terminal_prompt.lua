local M = {}

M.opts = {
  row_offset = 0,
}

function M.collect(source_ctx)
  local row_offset = source_ctx.opts.row_offset
  local ns = vim.api.nvim_get_namespaces()["nvim.terminal.prompt"]
  local bufnr = source_ctx.bufnr
  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return vim
    .iter(extmarks)
    :map(function(extmark)
      local row = extmark[2] + 1 + row_offset
      return {
        value = lines[row] or "",
        row = row,
        bufnr = bufnr,
      }
    end)
    :totable()
end

M.kind_name = "vim/position"

return M
