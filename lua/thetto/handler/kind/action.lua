local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    require("thetto").resume_execute({action_name = item.value, source_name = item.source_name})
  end
end

M.default_action = "execute"

return M
