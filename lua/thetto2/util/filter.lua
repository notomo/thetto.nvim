local M = {}

function M.by_name(name, fields)
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

function M.item(f)
  return {
    apply = function(_, items, _)
      return vim.iter(items):filter(f):totable()
    end,
    ignore_input = true,
  }
end

function M.is_ignorecase(ignorecase, smartcase, input)
  local case_sensitive = not ignorecase and smartcase and input:find("[A-Z]")
  return not case_sensitive
end

return M
