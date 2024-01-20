local M = {}

function M.by_name(source_name, fields, raw_opts)
  return require("thetto.core.source").by_name(source_name, fields, raw_opts)
end

function M.start_by_name(source_name, fields, opts)
  local source = require("thetto.core.source").by_name(source_name, fields)
  return require("thetto").start(source, opts)
end

return M
