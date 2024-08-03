local M = {}

local get_cursor_word = function(window_id)
  local column = vim.api.nvim_win_get_cursor(window_id)[2]
  local line = vim.api.nvim_win_call(window_id, function()
    return vim.api.nvim_get_current_line()
  end)

  local char_pattern = [=[[^[:space:]]]=]
  local pattern = ([=[\v\.?/%s*%%%dc]=]):format(char_pattern, column + 1)
  local cursor_word, start_byte = unpack(vim.fn.matchstrpos(line, pattern))
  if start_byte == -1 then
    return nil
  end

  return cursor_word
end

function M.collect(source_ctx)
  local cursor_word = get_cursor_word(source_ctx.window_id)
  if not cursor_word then
    return {}
  end

  local dir_path = vim.fs.dirname(cursor_word)
  return vim
    .iter(vim.fs.dir(dir_path))
    :map(function(name)
      local full_path = vim.fs.joinpath(dir_path, name)
      return {
        value = name,
        path = full_path,
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
