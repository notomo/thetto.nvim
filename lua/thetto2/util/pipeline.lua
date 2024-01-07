local M = {}

function M.default()
  return M.list({
    M.filter("substring"),
  })
end

function M.list(stages)
  return function()
    return require("thetto2.core.pipeline").new(stages)
  end
end

function M.filter(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.filter." .. name)
  if not origin then
    error("not found filter: " .. name)
  end

  local filter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  filter.name = name
  if vim.tbl_get(filter, "opts", "inversed") then
    filter.name = "-" .. filter.name
  end
  return filter
end

function M.is_ignorecase(ignorecase, smartcase, input)
  local case_sensitive = not ignorecase and smartcase and input:find("[A-Z]")
  return not case_sensitive
end

function M.sorter(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter." .. name)
  if not origin then
    error("not found sorter: " .. name)
  end

  local sorter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  sorter.name = name
  return sorter
end

function M.field_sorter_convert(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter.field._" .. name)
  if not origin then
    error("not found field sorter convert: " .. name)
  end
  return vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
end

return M
