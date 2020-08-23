local windowlib = require "thetto/lib/window"

local M = {}

local list_state_key = "_thetto_list_state"
M.path_pattern = "thetto://.+/thetto"

local State = {}
State.__index = State

function State.close(self, resume, offset)
  self:close_preview()
  if vim.api.nvim_win_is_valid(self.windows.list) then
    self.windows.list_cursor = vim.api.nvim_win_get_cursor(self.windows.list)
    self.windows.input_cursor = vim.api.nvim_win_get_cursor(self.windows.input)
    local active = "input"
    if vim.api.nvim_get_current_win() == self.windows.list then
      active = "list"
    end
    self.windows.active = active
    self.windows.mode = vim.api.nvim_get_mode().mode
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

function State._raw(self)
  return {buffers = self.buffers, windows = self.windows, started_at = self.started_at}
end

function State.open_preview(self, open_target)
  self:close_preview()

  local height = self.windows.preview_height + #self.buffers.filters
  local bufnr
  if open_target.bufnr ~= nil then
    bufnr = open_target.bufnr
  else
    bufnr = vim.api.nvim_create_buf(false, true)
    local f = io.open(open_target.path, "r")
    local lines = {}
    for _ = 0, height, 1 do
      local line = f:read()
      if line == nil then
        break
      end
      table.insert(lines, line)
    end
    io.close(f)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end

  local preview_window = vim.api.nvim_open_win(bufnr, false, {
    width = self.windows.preview_width,
    height = height,
    relative = "editor",
    row = self.windows.preview_row,
    col = self.windows.preview_column,
    focusable = false,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(preview_window, "scrollbind", false)
  vim.api.nvim_win_set_option(preview_window, "signcolumn", "no")

  local raw = self:_raw()
  raw.windows.preview = preview_window
  vim.api.nvim_buf_set_var(self.buffers.list, list_state_key, raw)
end

function State.close_preview(self)
  if self.windows.preview ~= nil then
    windowlib.close(self.windows.preview)
  end
end

M.resume = function(source_name)
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

  if recent == nil then
    return nil, "no source to resume"
  end
  return recent, nil
end

return M
