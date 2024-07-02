local M = {}

function M.unique()
  return function(_)
    return tostring(vim.uv.hrtime())
  end
end

function M.cwd()
  return function(key_ctx)
    local ctx_key = require("thetto.core.cwd").resolve(key_ctx.source.cwd):gsub("/", "__")
    return ctx_key
  end
end

return M
