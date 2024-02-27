local M = {}

function M.collect(source_ctx)
  local cmd = { "aws", "configure", "list-profiles" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    return {
      value = output,
    }
  end)
end

M.kind_name = "word"

return M
