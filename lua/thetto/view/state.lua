local M = {}

local State = {}
State.__index = State
M.State = State

function State.new(insert)
  local active = "list"
  local mode = "n"
  if insert then
    active = "input"
    mode = "i"
  end

  local tbl = {
    _active = active,
    _mode = mode,
    _input_cursor = nil,
    row = 1,
    _origin_window = vim.api.nvim_get_current_win(),
  }
  return setmetatable(tbl, State)
end

function State.save(self, item_list, inputter)
  if item_list:is_valid() then
    self.row = item_list:cursor()[1]

    if item_list:is_active() then
      self._active = "list"
    else
      self._active = "input"
    end

    self._mode = vim.api.nvim_get_mode().mode
  end

  if inputter:is_valid() then
    self._input_cursor = inputter:cursor()
  end

  local origin_window = self._origin_window
  self._origin_window = vim.api.nvim_get_current_win()
  return origin_window
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

  if self._input_cursor ~= nil then
    inputter:set_cursor(self._input_cursor)
    self._input_cursor = nil
  end
end

function State.update_row(self, offset, item_count, display_limit)
  local line_count = item_count
  if display_limit < line_count then
    line_count = display_limit
  end

  local row = self.row + offset
  if line_count < row then
    row = line_count
  elseif row < 1 then
    row = 1
  end

  self.row = row
end

return M
