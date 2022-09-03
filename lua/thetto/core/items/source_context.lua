local M = {}
M.__index = M

function M.new(pattern, cwd, debounce_ms, throttle_ms, range, is_interactive, bufnr, source_opts)
  local tbl = {
    pattern = pattern,
    cwd = cwd,
    debounce_ms = debounce_ms,
    throttle_ms = throttle_ms,
    range = range,
    interactive = is_interactive,
    bufnr = bufnr,
    opts = source_opts,
  }
  return setmetatable(tbl, M)
end

function M.from(self, pattern)
  return M.new(
    pattern,
    self.cwd,
    self.debounce_ms,
    self.throttle_ms,
    self.range,
    self.interactive,
    self.bufnr,
    self.opts
  )
end

return M
