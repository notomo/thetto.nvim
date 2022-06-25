local M = {}

function M.collect(_, source_ctx)
  local cmd = { "apt", "list" }
  return require("thetto.util").job.start(cmd, source_ctx, function(output)
    if output == "" then
      return nil
    end
    return { value = output }
  end)
end

M.kind_name = "word"

return M
