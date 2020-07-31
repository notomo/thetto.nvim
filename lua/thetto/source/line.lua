local M = {}

M.collect = function()
  local bufnr = 0
  local kind_name = nil
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not vim.bo.modified and vim.fn.filereadable(path) == 1 then
    kind_name = "file"
  else
    path = nil
  end

  local items = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  for i, line in ipairs(lines) do
    table.insert(items, {value = line, row = i, kind_name = kind_name, path = path})
  end
  return items
end

M.kind_name = "position"

return M
