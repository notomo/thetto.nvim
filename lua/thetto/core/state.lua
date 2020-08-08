local bufferlib = require "thetto/lib/buffer"
local windowlib = require "thetto/lib/window"

local M = {}

local list_state_key = "_thetto_list_state"
local input_state_key = "_thetto_input_state"
local info_state_key = "_thetto_info_state"

M.list_filetype = "thetto"
M.sign_filetype = "thetto-sign"
M.input_filetype = "thetto-input"
M.info_filetype = "thetto-info"
M.filter_info_filetype = "thetto-filter-info"
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
    windowlib.close(self.windows.list)
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
  if vim.api.nvim_win_is_valid(self.windows.origin) then
    vim.api.nvim_set_current_win(self.windows.origin)
  end
end

function State.selected_items(self, action_name, offset)
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self.buffers.selected) then
    local selected = vim.tbl_values(self.buffers.selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  local index
  local filetype = vim.bo.filetype
  if filetype == M.input_filetype or filetype == M.info_filetype then
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

function State.update_filters(self, filter_names)
  local raw = self:_raw()
  raw.buffers.filters = filter_names
  vim.api.nvim_buf_set_var(self.buffers.list, list_state_key, raw)
end

function State.toggle_selections(self, items)
  local raw = self:_raw()
  for _, item in ipairs(items) do
    local key = tostring(item.index)
    if raw.buffers.selected[key] then
      raw.buffers.selected[key] = nil
    else
      raw.buffers.selected[key] = item
    end

    for _, filtered_item in ipairs(raw.buffers.filtered) do
      if filtered_item.index == item.index then
        filtered_item.selected = not filtered_item.selected
        break
      end
    end
  end

  vim.api.nvim_buf_set_var(self.buffers.list, list_state_key, raw)
end

M.set = function(buffers, windows)
  local raw_state = {}
  raw_state.buffers = buffers
  raw_state.windows = windows
  -- HACk: save started_at as str
  raw_state.started_at = vim.fn.reltimestr(vim.fn.reltime())

  vim.api.nvim_buf_set_var(raw_state.buffers.list, list_state_key, raw_state)

  local simple = {
    buffers = {
      list = raw_state.buffers.list,
      input = raw_state.buffers.input,
      info = raw_state.buffers.info,
    },
    windows = {
      list = raw_state.windows.list,
      input = raw_state.windows.input,
      info = raw_state.windows.info,
    },
  }
  vim.api.nvim_buf_set_var(raw_state.buffers.input, input_state_key, simple)
  vim.api.nvim_buf_set_var(raw_state.buffers.info, info_state_key, simple)
end

M.get = function(bufnr, input_bufnr)
  local raw_state
  if input_bufnr ~= nil then
    local input_state = bufferlib.find_var(input_bufnr, input_state_key)
    raw_state = vim.api.nvim_buf_get_var(input_state.buffers.list, list_state_key)
  elseif bufnr == 0 and vim.bo.filetype == M.input_filetype then
    local input_state = bufferlib.find_var(bufnr, input_state_key)
    raw_state = vim.api.nvim_buf_get_var(input_state.buffers.list, list_state_key)
  elseif bufnr == 0 and vim.bo.filetype == M.info_filetype then
    local info_state = bufferlib.find_var(bufnr, info_state_key)
    raw_state = vim.api.nvim_buf_get_var(info_state.buffers.list, list_state_key)
  else
    raw_state = bufferlib.find_var(bufnr, list_state_key)
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
