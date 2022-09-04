local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    require("thetto").start(item.value)
  end
end

function M.action_resume(items)
  local item = items[1]
  if not item then
    return
  end
  require("thetto").resume(item.value)
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
