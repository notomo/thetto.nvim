local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    if item.quit then
      require("thetto").resume_execute({action_name = item.value, source_name = item.source_name})
    else
      require("thetto").resume(item.source_name)
      require("thetto").execute(item.value)
    end
  end
end

M.default_action = "execute"

return M
