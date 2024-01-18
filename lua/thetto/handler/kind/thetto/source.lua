local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name(item.value)
    return require("thetto").start(source)
  end
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
