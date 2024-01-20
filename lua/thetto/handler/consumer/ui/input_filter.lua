local _line_histories = {}

--- @class ThettoUiInputFilter
--- @field private _current_index integer
local M = {}
M.__index = M

function M.new(source_name, filter_name)
  local key = ("%s_%s"):format(source_name, filter_name)
  local tbl = {
    _line_history = _line_histories[key] or {},
    _current_index = 0,
  }
  local self = setmetatable(tbl, M)
  _line_histories[key] = self._line_history
  return self
end

function M.recall_history(self, offset, current_line)
  if self._current_index == 0 and #self._line_history == 0 then
    self:append(current_line)
    self._current_index = 1
  end

  local index = self._current_index + offset
  index = math.min(index, #self._line_history)
  index = math.max(0, index)

  self._current_index = index

  return self._line_history[index] or ""
end

function M.append(self, input_line)
  if input_line == "" then
    return
  end

  for i, line in ipairs(self._line_history) do
    if input_line == line then
      table.remove(self._line_history, i)
      break
    end
  end
  table.insert(self._line_history, 1, input_line)
end

return M
