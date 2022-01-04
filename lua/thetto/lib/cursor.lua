local M = {}

local get_row = function(row, bufnr)
  local count = vim.api.nvim_buf_line_count(bufnr or 0)
  if row > count then
    return count
  end
  if row < 1 then
    return 1
  end
  return row
end

function M.set_row(row, window_id, bufnr)
  vim.api.nvim_win_set_cursor(window_id or 0, { get_row(row, bufnr), 0 })
end

return M
