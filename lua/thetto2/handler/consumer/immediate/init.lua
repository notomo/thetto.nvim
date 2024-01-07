--- @class ThettoImmediate
--- @field _all_items table
--- @field _item_cursor_row integer
local M = {}
M.__index = M

function M.new(consumer_ctx, action_name, callbacks)
  local tbl = {
    _all_items = {},
    _action_name = action_name,
    _item_cursor_row = consumer_ctx.item_cursor_row,
    _on_row_changed = callbacks.on_row_changed,
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
  [consumer_events.all.source_completed] = function(self, item_cursor)
    local row = math.max(1, self._item_cursor_row + item_cursor.row_offset)
    row = math.min(row, #self._all_items)
    self._item_cursor_row = row
    self._on_row_changed(row)

    local item = self._all_items[row]
    local action_item_groups = require("thetto2.util.action").grouping({ item }, { action_name = self._action_name })
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
