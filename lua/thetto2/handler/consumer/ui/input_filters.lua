local M = {}
M.__index = M

function M.new(source_name, filters)
  local tbl = {
    _input_filters = vim.tbl_map(function(filter)
      return require("thetto2.handler.consumer.ui.input_filter").new(source_name, filter.name)
    end, filters),
  }
  return setmetatable(tbl, M)
end

function M.recall_history(self, row, offset, current_line)
  local input_filter = self._input_filters[row]
  if not input_filter then
    return
  end
  return input_filter:recall_history(offset, current_line)
end

function M.append(self, input_lines)
  for row, input_filter in ipairs(self._input_filters) do
    local input_line = input_lines[row] or ""
    input_filter:append(input_line)
  end
end

return M
