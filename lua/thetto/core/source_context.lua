local M = {}
M.__index = M

function M.new(pattern, cwd, debounce_ms, allow_empty, range, is_interactive)
  local tbl = {
    pattern = pattern,
    cwd = cwd,
    debounce_ms = debounce_ms,
    allow_empty = allow_empty,
    range = range,
    interactive = is_interactive,
  }
  return setmetatable(tbl, M)
end

function M.from(self, pattern)
  return M.new(pattern, self.cwd, self.debounce_ms, self.allow_empty, self.range, self.interactive)
end

return M
