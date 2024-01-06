local M = {}

function M.default()
  return M.by_names({
    "filter.substring",
  })
end

function M.by_names(names)
  local stages = vim
    .iter(names)
    :map(function(name)
      return require("thetto2.handler.pipeline." .. name)
    end)
    :totable()
  return M.list(stages)
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
  return filter
end

function M.is_ignorecase(ignorecase, smartcase, input)
  local case_sensitive = not ignorecase and smartcase and input:find("[A-Z]")
  return not case_sensitive
end

return M
