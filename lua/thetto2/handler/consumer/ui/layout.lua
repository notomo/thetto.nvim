local M = {}

function M.new(has_sidecar, raw_input_filters)
  local entire_height = vim.o.lines
  local entire_width = vim.o.columns

  local height = math.floor(entire_height * 0.5)
  local width = math.floor(entire_width * 0.6)

  local left_column = 2
  local sidecar_width = math.ceil(entire_width - left_column - width - 3 - 2)

  local inputter_height = math.max(#raw_input_filters, 1)

  local row = (entire_height - height) / 2
  local column = (entire_width - width) / 2
  if has_sidecar then
    column = left_column
  else
    column = (entire_width - width) / 2
  end

  local border_char = "─"
  if vim.o.ambiwidth == "double" then
    border_char = "-"
  end

  return {
    item_list = {
      height = height - 1,
      width = width - 2, -- NOTICE: calc border width
      row = row,
      column = column,
      border_char = border_char,
    },
    inputter = {
      width = width - 2, -- NOTICE: calc border width
      height = inputter_height,
      row = row + height + 1,
      column = column,
    },
    sidecar = {
      width = sidecar_width,
      height = height + inputter_height,
      row = row,
      column = left_column + width + 1,
      border_char = border_char,
    },
  }
end

return M
