local M = {}

M.make = function()
  local candidates = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  for i, line in ipairs(lines) do
    table.insert(candidates, {value = line, row = i})
  end
  return candidates
end

M.kind_name = "position"

return M
