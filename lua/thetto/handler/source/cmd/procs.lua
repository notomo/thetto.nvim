local M = {}

function M.collect(source_ctx)
  local cmd = { "procs", "--pager", "disable", "--tree" }
  local row = 0
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    row = row + 1
    if row <= 2 then
      return {
        value = output,
        kind_name = "word",
      }
    end

    local pid = output:match("%d+")
    return {
      value = output,
      pid = pid,
    }
  end)
end

M.kind_name = "env/process"

return M
