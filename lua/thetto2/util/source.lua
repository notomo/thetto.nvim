local M = {}

function M.by_name(source_name)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.source." .. source_name)
  if not origin then
    error("not found source: " .. source_name)
  end

  local source = vim.deepcopy(origin)
  source.name = source_name
  return source
end

return M
