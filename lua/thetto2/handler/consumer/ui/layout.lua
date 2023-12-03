local M = {}

function M.new()
  local entire_height = vim.o.lines
  local entire_width = vim.o.columns

  local height = math.floor(entire_height * 0.5)
  local width = math.floor(entire_width * 0.6)

  local row = (entire_height - height) / 2
  local column = (entire_width - width) / 2
  return {
    height = height,
    width = width,
    row = row,
    column = column,
  }
end

return M
