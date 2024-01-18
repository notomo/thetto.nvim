--- @class ThettoSkeleton
local M = {}
M.__index = M

function M.new(events)
  local tbl = { _events = events }
  return setmetatable(tbl, M)
end

function M.consume(self, event_name, ...)
  table.insert(self._events, { event_name, ... })
end

local actions = {}

function M.call(self, action_name)
  local action = actions[action_name]
  if not action then
    return
  end
  return action(self)
end

return M
