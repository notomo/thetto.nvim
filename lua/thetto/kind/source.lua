local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    require("thetto").start(item.value)
  end
end

M.default_action = "execute"

return M
