local M = {}

--- @class ThettoSourceContext
--- @field cwd string
--- @field bufnr integer
--- @field window_id integer
--- @field pattern string
--- @field cursor_word {str:string,offset:integer}
--- @field opts table
--- @field store_to_restart table?

local get_pattern = function(source, source_input_pattern)
  local pattern = source_input_pattern
  if not pattern and source.get_pattern then
    pattern = source.get_pattern()
  end
  return pattern or ""
end

local get_cursor_word = function(source, source_window_id)
  local cursor_word
  if source.get_cursor_word then
    cursor_word = source.get_cursor_word(source_window_id)
  end
  return cursor_word or {
    str = "",
    offset = 1,
  }
end

--- @return ThettoSourceContext
function M.new(source, source_bufnr, source_window_id, source_input_pattern, store_to_restart)
  return {
    pattern = get_pattern(source, source_input_pattern),
    cursor_word = get_cursor_word(source, source_window_id),
    cwd = require("thetto.core.cwd").resolve(source.cwd),
    bufnr = source_bufnr,
    window_id = source_window_id,
    opts = source.opts or {},
    store_to_restart = store_to_restart,
  }
end

function M.from(source, source_ctx)
  return {
    pattern = get_pattern(source, nil),
    cursor_word = source_ctx.cursor_word,
    cwd = require("thetto.core.cwd").resolve(source.cwd),
    bufnr = source_ctx.bufnr,
    window_id = source_ctx.window_id,
    opts = source.opts or {},
    store_to_restart = source_ctx.store_to_restart,
  }
end

return M
