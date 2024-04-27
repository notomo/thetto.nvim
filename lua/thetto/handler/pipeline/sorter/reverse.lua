local M = {}

function M.apply(_, items, _)
  return vim.iter(items):rev():totable()
end

M.is_sorter = true
M.ignore_input = true

return M
