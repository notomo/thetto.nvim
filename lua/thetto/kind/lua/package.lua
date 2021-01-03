local M = {}

M.action_unload = function(_, items)
  for _, item in ipairs(items) do
    package.loaded[item.value] = nil
  end
end

return M
