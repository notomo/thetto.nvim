local State = {}
State.__index = State

function State.new(insert)
  if insert then
    return State._new("input", "i")
  end
  return State._new("list", "n")
end

function State._new(active, mode, row, origin_window, input_cursor)
  local tbl = {
    _active = active,
    _mode = mode,
    row = row or 1,
    _origin_window = origin_window or vim.api.nvim_get_current_win(),
    _input_cursor = input_cursor,
  }
  return setmetatable(tbl, State)
end

function State._clone(self, update, remove)
  update.active = update.active or self._active
  update.mode = update.mode or self._mode
  update.row = update.row or self.row
  update.origin_window = update.origin_window or self._origin_window
  update.input_cursor = update.input_cursor or self._input_cursor
  for k in pairs(remove or {}) do
    update[k] = nil
  end
  return State._new(update.active, update.mode, update.row, update.origin_window, update.input_cursor)
end

function State.save(self, item_list, inputter)
  local row, active, mode
  if item_list:is_valid() then
    row = item_list:cursor()[1]
    active = item_list:is_active() and "list" or "input"
    mode = vim.api.nvim_get_mode().mode
  end

  local input_cursor
  if inputter:is_valid() then
    input_cursor = inputter:cursor()
  end

  local state = self:_clone({
    active = active,
    mode = mode,
    row = row,
    input_cursor = input_cursor,
    origin_window = vim.api.nvim_get_current_win(),
  })
  return self._origin_window, state
end

function State.resume(self, item_list, inputter)
  if self._active == "input" then
    inputter:enter()
  else
    item_list:enter()
  end

  if self._mode == "n" then
    vim.cmd("stopinsert")
  else
    vim.cmd("startinsert")
  end

  if not self._input_cursor then
    return self
  end
  inputter:set_cursor(self._input_cursor)
  return self:_clone({}, { input_cursor = true })
end

function State.update_row(self, offset, item_count, display_limit)
  local line_count = math.min(item_count, display_limit)
  local row = math.min(line_count, self.row + offset)
  return self:_clone({ row = math.max(row, 1) })
end

return State
