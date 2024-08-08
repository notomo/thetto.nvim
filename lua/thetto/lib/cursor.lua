local vim = vim
local fn = vim.fn

local M = {}

function M.word(window_id, word_pattern)
  word_pattern = word_pattern or [=[\k*]=]
  local column = vim.api.nvim_win_get_cursor(window_id)[2]
  local pattern = ([=[\v%s%%%dc]=]):format(word_pattern, column + 1)

  local line = vim.api.nvim_win_call(window_id, function()
    return vim.api.nvim_get_current_line()
  end)
  local str, offset = unpack(fn.matchstrpos(line, pattern))
  if offset == -1 then
    return nil
  end

  return {
    str = str,
    offset = offset + 1,
  }
end

return M
