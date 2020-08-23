local Notifier = {}
Notifier.__index = Notifier

function Notifier.send(self, method, ...)
  local callback = self.callbacks[method]
  if callback == nil then
    return "not found method: " .. method
  end
  return callback(unpack({...}))
end

function Notifier.on(self, method, callback)
  self.callbacks[method] = callback
end

local M = {}

M.new = function()
  local notifier = {callbacks = {}}
  return setmetatable(notifier, Notifier)
end

return M
