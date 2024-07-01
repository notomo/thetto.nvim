local M = {}

--- @class ThettoSourceContext
--- @field cwd string
--- @field bufnr integer
--- @field window_id integer
--- @field pattern string
--- @field opts table
--- @field store_to_restart table?

--- @return ThettoSourceContext
function M.new(source, source_bufnr, source_window_id, source_input_pattern, store_to_restart)
  local pattern = source_input_pattern
  if not pattern and source.get_pattern then
    pattern = source.get_pattern()
  end

  return {
    cwd = require("thetto.core.cwd").resolve(source.cwd),
    bufnr = source_bufnr,
    window_id = source_window_id,
    pattern = pattern or "",
    opts = source.opts or {},
    store_to_restart = store_to_restart,
  }
end

return M
