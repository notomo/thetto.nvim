local M = {}
M.__index = M

function M.new(pattern, cwd, debounce_ms, allow_empty, is_interactive)
  local tbl = {
    pattern = pattern,
    cwd = cwd,
    debounce_ms = debounce_ms,
    allow_empty = allow_empty,
    interactive = is_interactive,
  }
  return setmetatable(tbl, M)
end

return M
