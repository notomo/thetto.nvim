local M = {}

function M.action_unload(items)
  for _, item in ipairs(items) do
    package.loaded[item.value] = nil
  end
end

return M
