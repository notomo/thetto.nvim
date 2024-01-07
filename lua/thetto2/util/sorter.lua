local M = {}

function M.by_name(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter." .. name)
  if not origin then
    error("not found sorter: " .. name)
  end

  local sorter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  sorter.name = name
  return sorter
end

function M.field_convert(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter.field._" .. name)
  if not origin then
    error("not found field sorter convert: " .. name)
  end
  return vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
end

return M
