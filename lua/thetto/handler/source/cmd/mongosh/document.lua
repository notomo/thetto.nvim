local M = {}

M.opts = {
  database_name = "local",
  collection_name = "startup_log",
}

function M.collect(source_ctx)
  local query = ([[db.getMongo().getDB("%s").getCollection("%s").find({})]]):format(
    source_ctx.opts.database_name,
    source_ctx.opts.collection_name
  )
  local cmd = { "mongosh", "--quiet", "--eval", query }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    return {
      value = output,
    }
  end)
end

M.kind_name = "word"

return M
