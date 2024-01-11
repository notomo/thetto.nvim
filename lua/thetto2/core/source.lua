local M = {}

local _registered = {}

local default_opts = {
  use_registered = true,
}
function M.by_name(source_name, fields, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts or {})

  local registered = _registered[source_name]
  if opts.use_registered and registered then
    return vim.tbl_deep_extend("force", vim.deepcopy(registered), fields or {})
  end

  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.source." .. source_name)
  if not origin then
    error("not found source: " .. source_name)
  end

  local source = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  source.name = source_name
  source.can_resume = source.can_resume == nil and true or source.can_resume
  return source
end

function M.register(source_name, source)
  _registered[source_name] = source
end

return M
