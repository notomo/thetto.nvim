local M = {}

function M.apply(_, items, _)
  return items
end

M.is_filter = true
M.is_source_input = true
M.debounce_ms = 300

return M
