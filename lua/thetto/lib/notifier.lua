local M = {}

local Notifier = {}
Notifier.__index = Notifier
M.Notifier = Notifier

function Notifier.new()
  local notifier = {callbacks = {}}
  return setmetatable(notifier, Notifier)
end

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

return M
