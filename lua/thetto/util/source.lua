local M = {}

function M.by_name(source_name, fields, raw_opts)
  return require("thetto.core.source").by_name(source_name, fields, raw_opts)
end

function M.start_by_name(source_name, fields, opts)
  local source = require("thetto.core.source").by_name(source_name, fields)
  return require("thetto").start(source, opts)
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
