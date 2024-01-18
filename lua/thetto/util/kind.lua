local M = {}

function M.by_name(kind_name, fields, raw_opts)
  return require("thetto.core.kind").by_name(kind_name, fields, raw_opts)
end

return M
