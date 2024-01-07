local M = {}

function M.apply(_, items, _)
  return vim.iter(items):rev():totable()
end

M.is_sorter = true

return M
