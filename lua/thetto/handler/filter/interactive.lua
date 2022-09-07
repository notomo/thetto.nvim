local M = {}

function M.apply(_, _, items)
  -- Note: if this filter exists, interactive mode is started.
  return items
end

M.debounce_ms = 300

return M
