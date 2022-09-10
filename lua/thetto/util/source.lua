local M = {}

function M.get_input(source_ctx)
  local pattern = source_ctx.pattern
  if not source_ctx.interactive and not pattern then
    pattern = vim.fn.input("Pattern: ")
  end

  if not pattern or pattern == "" then
    return nil, function(observer)
      observer:complete()
    end
  end

  return pattern, nil
end

return M
