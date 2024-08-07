local vim = vim
local fn = vim.fn

local M = {}

function M.word(window_id)
  local column = vim.api.nvim_win_get_cursor(window_id)[2]
  local pattern = ([=[\v\k*%%%dc]=]):format(column + 1)

  local line = vim.api.nvim_win_call(window_id, function()
    return vim.api.nvim_get_current_line()
  end)
  local str, offset = unpack(fn.matchstrpos(line, pattern))

  return {
    str = str,
    offset = offset + 1,
  }
end

return M
