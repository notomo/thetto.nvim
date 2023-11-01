local M = {}

M.opts = {
  collect = function(_)
    return {}
  end,
}

function M.collect(source_ctx)
  return source_ctx.opts.collect(source_ctx)
end

return M
