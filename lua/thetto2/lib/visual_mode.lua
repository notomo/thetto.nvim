local M = {}

function M.range()
  local range = {
    vim.fn.line("v"),
    vim.fn.line("."),
  }
  table.sort(range, function(a, b)
    return a < b
  end)
  return range
end

return M
