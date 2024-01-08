local M = {}

function M.collect(source_ctx)
  local cmd = { "brew", "list", "-1" }
  return require("thetto2.util.job").start(cmd, source_ctx, function(output)
    return { value = output }
  end)
end

M.kind_name = "word"

M.actions = {
  action_update = function(items)
    local item = items[1]
    if not item then
      return
    end
    -- use install to update one package
    local cmd = { "brew", "install", item.value }
    return require("thetto2.util.job").execute(cmd)
  end,
}

return M
