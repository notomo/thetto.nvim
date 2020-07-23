local util = require "thetto/util"

local M = {}

local list_state_key = "_thetto_list_state"
local input_state_key = "_thetto_input_state"

M.list_filetype = "thetto"
M.input_filetype = "thetto-input"
M.path_pattern = "thetto://.+/thetto"

local State = {}
State.__index = State

function State.close(self, resume, offset)
  if vim.api.nvim_win_is_valid(self.windows.list) then
    self.windows.list_cursor = vim.api.nvim_win_get_cursor(self.windows.list)
    self.windows.input_cursor = vim.api.nvim_win_get_cursor(self.windows.input)
    local active = "input"
    if vim.api.nvim_get_current_win() == self.windows.list then
      active = "list"
    end
    self.windows.active = active
    util.close_window(self.windows.list)
  end
  if resume then
    local cursor = self.windows.list_cursor
    cursor[1] = cursor[1] + offset
    local line_count = vim.api.nvim_buf_line_count(self.buffers.list)
    if line_count < cursor[1] then
      cursor[1] = line_count
    elseif cursor[1] < 1 then
      cursor[1] = 1
    end
    self.windows.list_cursor = cursor
  end
  vim.api.nvim_buf_set_var(self.buffers.list, list_state_key, self)
end

function State.selected_items(self, offset)
  local index
  if vim.bo.filetype == M.input_filetype then
    index = 1
  elseif vim.bo.filetype == M.list_filetype then
    index = vim.fn.line(".")
  else
    index = self.windows.list_cursor[1]
  end
  return {self.buffers.filtered[index + offset]}
end

function State._raw(self)
  return {buffers = self.buffers, windows = self.windows, started_at = self.started_at}
end

function State.update(self, filtered)
  local raw = self:_raw()
  raw.buffers.filtered = filtered
  vim.api.nvim_buf_set_var(self.buffers.list, list_state_key, raw)
end

M.set = function(buffers, windows)
  local raw_state = {}
  raw_state.buffers = buffers
  raw_state.windows = windows
  -- HACk: save started_at as str
  raw_state.started_at = vim.fn.reltimestr(vim.fn.reltime())

  vim.api.nvim_buf_set_var(raw_state.buffers.list, list_state_key, raw_state)
  vim.api.nvim_buf_set_var(raw_state.buffers.input, input_state_key, {
    buffers = {list = raw_state.buffers.list, input = raw_state.buffers.input},
    windows = {list = raw_state.windows.list, input = raw_state.windows.input},
  })
end

M.get = function(bufnr)
  local raw_state = util.buffer_var(bufnr, list_state_key)
  if bufnr == 0 and vim.bo.filetype == M.input_filetype then
    local input_state = util.buffer_var(bufnr, input_state_key)
    raw_state = vim.api.nvim_buf_get_var(input_state.buffers.list, list_state_key)
  end
  if raw_state == nil then
    return nil, "not found state"
  end
  return setmetatable(raw_state, State), nil
end

M.recent = function(source_name)
  local pattern = M.path_pattern
  if source_name ~= nil then
    pattern = ("thetto://%s/thetto"):format(source_name)
  end

  local states = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path:match(pattern) then
      local state = M.get(bufnr)
      table.insert(states, state)
    end
  end

  local recent = nil
  local recent_time = 0
  for _, state in ipairs(states) do
    if recent_time < tonumber(state.started_at) then
      recent = state
    end
  end

  return recent
end

return M
