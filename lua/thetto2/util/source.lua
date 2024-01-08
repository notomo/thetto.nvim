local M = {}

function M.by_name(source_name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.source." .. source_name)
  if not origin then
    error("not found source: " .. source_name)
  end

  local source = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  source.name = source_name
  return source
end

function M.get_input(source_ctx)
  local pattern = source_ctx.pattern
  if not source_ctx.interactive and not pattern then
    pattern = vim.fn.input("Pattern: ")
  end

  if not pattern or pattern == "" then
    return nil, function(observer)
      observer:next({})
      observer:complete()
    end
  end

  return pattern, nil
end

return M
