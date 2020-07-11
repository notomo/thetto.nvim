local util = require "thetto/util"

local M = {}

local list_state_key = "_thetto_list_state"
local filter_state_key = "_thetto_filter_state"

M.list_filetype = "thetto"
M.filter_filetype = "thetto-filter"

local wrap = function(raw_state)
  return {
    list = raw_state.list,
    filter = raw_state.filter,
    kind_name = raw_state.kind_name,
    update = function(filtered)
      raw_state.list.filtered = filtered
      vim.api.nvim_buf_set_var(raw_state.list.bufnr, list_state_key, raw_state)
    end,
    fixed = function()
      return {list = raw_state.list, filter = raw_state.filter}
    end,
    select_from_list = function()
      local index = 1
      if vim.bo.filetype == M.list_filetype then
        index = vim.fn.line(".")
      end
      return raw_state.list.filtered[index]
    end,
    close = function()
      util.close_window(raw_state.list.window)
    end
  }
end

M.get = function()
  local state = vim.b[list_state_key]
  if vim.bo.filetype == M.filter_filetype then
    local filter_state = vim.b[filter_state_key]
    state = vim.api.nvim_buf_get_var(filter_state.list.bufnr, list_state_key)
  end
  return wrap(state)
end

M.set = function(list_buffer, filter_buffer, kind_name)
  local raw_state = {list = list_buffer, filter = filter_buffer, kind_name = kind_name}
  vim.api.nvim_buf_set_var(list_buffer.bufnr, list_state_key, raw_state)
  local state = wrap(raw_state)
  vim.api.nvim_buf_set_var(filter_buffer.bufnr, filter_state_key, state.fixed())
end

return M
