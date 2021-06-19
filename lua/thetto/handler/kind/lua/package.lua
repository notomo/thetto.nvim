local M = {}

function M.action_unload(_, items)
  for _, item in ipairs(items) do
    package.loaded[item.value] = nil
  end
end

return M
