local M = {}

function M.collect()
  return {}
end

function M.highlight(_, _, _, _) end

M.filters = { "substring" }
M.sorters = {}
M.kind_name = "base"

return M
