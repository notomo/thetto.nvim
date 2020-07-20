local util = require "thetto/util"

local M = {}

local list_state_key = "_thetto_list_state"
local input_state_key = "_thetto_input_state"

M.list_filetype = "thetto"
M.input_filetype = "thetto-input"
M.path_pattern = "thetto://.+/thetto"

local wrap = function(raw_state)
  return {
    buffers = raw_state.buffers,
    windows = raw_state.windows,
    started_at = raw_state.started_at,
    update = function(filtered)
      raw_state.buffers.filtered = filtered
      vim.api.nvim_buf_set_var(raw_state.buffers.list, list_state_key, raw_state)
    end,
    fixed = function()
      return {buffers = raw_state.buffers, windows = raw_state.windows}
    end,
    select_from_list = function(offset)
      local index
      if vim.bo.filetype == M.input_filetype then
        index = 1
      elseif vim.bo.filetype == M.list_filetype then
        index = vim.fn.line(".")
      else
        index = raw_state.windows.list_cursor[1]
      end
      return raw_state.buffers.filtered[index + offset]
    end,
    close = function(args)
      if vim.api.nvim_win_is_valid(raw_state.windows.list) then
        raw_state.windows.list_cursor = vim.api.nvim_win_get_cursor(raw_state.windows.list)
        raw_state.windows.input_cursor = vim.api.nvim_win_get_cursor(raw_state.windows.input)
        local active = "input"
        if vim.api.nvim_get_current_win() == raw_state.windows.list then
          active = "list"
        end
        raw_state.windows.active = active
        util.close_window(raw_state.windows.list)
      end
      if args.resume then
        local cursor = raw_state.windows.list_cursor
        cursor[1] = cursor[1] + args.offset
        local line_count = vim.api.nvim_buf_line_count(raw_state.buffers.list)
        if line_count < cursor[1] then
          cursor[1] = line_count
        elseif cursor[1] < 1 then
          cursor[1] = 1
        end
        raw_state.windows.list_cursor = cursor
      end
      vim.api.nvim_buf_set_var(raw_state.buffers.list, list_state_key, raw_state)
    end,
    closed = function()
      return not vim.api.nvim_win_is_valid(raw_state.windows.list)
    end,
  }
end

M.get = function(bufnr)
  local state = util.buffer_var(bufnr, list_state_key)
  if bufnr == 0 and vim.bo.filetype == M.input_filetype then
    local input_state = util.buffer_var(bufnr, input_state_key)
    state = vim.api.nvim_buf_get_var(input_state.buffers.list, list_state_key)
  end
  if state == nil then
    return nil, "not found state"
  end
  return wrap(state), nil
end

M.set = function(buffers, windows)
  -- HACk: save started_at as str
  local raw_state = {
    buffers = buffers,
    windows = windows,
    started_at = vim.fn.reltimestr(vim.fn.reltime()),
  }
  vim.api.nvim_buf_set_var(buffers.list, list_state_key, raw_state)
  local state = wrap(raw_state)
  vim.api.nvim_buf_set_var(buffers.input, input_state_key, state.fixed())
end

M.recent = function(source_name)
  local bufnrs = vim.api.nvim_list_bufs()
  local states = {}

  local pattern = M.path_pattern
  if source_name ~= nil then
    pattern = ("thetto://%s/thetto"):format(source_name)
  end

  for _, bufnr in ipairs(bufnrs) do
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
