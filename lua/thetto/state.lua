local util = require "thetto/util"

local M = {}

local list_state_key = "_thetto_list_state"
local input_state_key = "_thetto_input_state"

M.list_filetype = "thetto"
M.input_filetype = "thetto-input"

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
    select_from_list = function()
      local index = 1
      if vim.bo.filetype == M.list_filetype then
        index = vim.fn.line(".")
      end
      return raw_state.buffers.filtered[index]
    end,
    close = function()
      util.close_window(raw_state.windows.list)
    end,
  }
end

M.get = function(bufnr)
  local state = util.buffer_var(bufnr, list_state_key)
  if vim.bo.filetype == M.input_filetype then
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

M.set_all_items = function(input_bufnr, items)
  local input_state = util.buffer_var(input_bufnr, input_state_key)
  local state = vim.api.nvim_buf_get_var(input_state.buffers.list, list_state_key)
  state.buffers.all = items
  vim.api.nvim_buf_set_var(state.buffers.list, list_state_key, state)
end

M.recent = function(source_name)
  local bufnrs = vim.api.nvim_list_bufs()
  local states = {}

  local pattern = "thetto://%w+/thetto"
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
