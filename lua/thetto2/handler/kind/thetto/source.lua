local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local source = require("thetto2.util.source").by_name(item.value)
    return require("thetto2").start(source)
  end
end

M.default_action = "execute"

return require("thetto2.core.kind").extend(M, "file")
