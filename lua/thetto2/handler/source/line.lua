local M = {}

M.opts = {
  bufnr = nil,
  start_row = 0,
  end_row = -1,
}

function M.collect(source_ctx)
  local bufnr = source_ctx.opts.bufnr or vim.api.nvim_get_current_buf()
  local kind_name = nil
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not vim.bo.modified and vim.fn.filereadable(path) == 1 then
    kind_name = "file"
  else
    path = nil
  end

  local items = {}
  local start_row = math.max(0, source_ctx.opts.start_row)
  local end_row = math.min(source_ctx.opts.end_row, vim.api.nvim_buf_line_count(bufnr))
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, true)
  for i, line in ipairs(lines) do
    table.insert(items, {
      value = line,
      row = start_row + i,
      kind_name = kind_name,
      path = path,
      bufnr = bufnr,
    })
  end
  return items
end

M.kind_name = "position"

return M
