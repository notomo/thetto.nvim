--- @class ThettoImmediate
--- @field _all_items table
local M = {}
M.__index = M

function M.new(consumer_ctx)
  local tbl = {
    _all_items = {},
  }
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto2.core.consumer_events")

local handlers = {
  --- @param self ThettoImmediate
  [consumer_events.all.items_changed] = function(self, items, _)
    self._all_items = items
  end,
  --- @param self ThettoImmediate
  [consumer_events.all.source_completed] = function(self)
    local items = { self._all_items[1] }
    local action_item_groups = require("thetto2.util.action").by_name(nil, items)
    return require("thetto2.core.executor").execute(action_item_groups)
  end,
  [consumer_events.all.source_error] = function(_, err)
    error(err)
  end,
}

function M.consume(self, event_name, ...)
  local handler = handlers[event_name]
  if not handler then
    return
  end
  return handler(self, ...)
end

local actions = {}

function M.call(self, action_name)
  local action = actions[action_name]
  if not action then
    return
  end
  return action(self)
end

function M.get_items(self)
  return self._all_items
end

return M
