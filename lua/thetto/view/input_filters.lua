local InputFilter = require("thetto.view.input_filter")

local InputFilters = {}
InputFilters.__index = InputFilters

function InputFilters.new(source_name, filters)
  local input_filters = vim.tbl_map(function(filter)
    return InputFilter.new(source_name, filter.name)
  end, filters:values())
  local tbl = {
    _input_filters = input_filters,
  }
  return setmetatable(tbl, InputFilters)
end

function InputFilters.recall_history(self, row, offset, current_line)
  local input_filter = self._input_filters[row]
  if not input_filter then
    return
  end
  return input_filter:recall_history(offset, current_line)
end

function InputFilters.append(self, input_lines)
  for row, input_filter in ipairs(self._input_filters) do
    local input_line = input_lines[row] or ""
    input_filter:append(input_line)
  end
end

return InputFilters
