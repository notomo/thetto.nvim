local M = {}

function M.collect(source_ctx)
  local cmd = { "brew", "list", "-1" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
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
    local result = require("thetto.util.job").execute(cmd)
    if type(result) == "string" then
      local err = result
      return nil, err
    end
  end,
}

return M
