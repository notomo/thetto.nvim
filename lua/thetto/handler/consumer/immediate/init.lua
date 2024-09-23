--- @class ThettoImmediate
--- @field _all_items table
--- @field _item_cursor_row integer
--- @field _is_valid fun(item:table):boolean
--- @field _actions table
--- @field _action_name string?
--- @field _on_row_changed fun(row)
--- @field _item_cursor_factory fun(all_items:table):ThettoItemCursor
local M = {}
M.__index = M

local default_opts = {
  action_name = nil,
  is_valid = function(_)
    return true
  end,
}

function M.new(consumer_ctx, callbacks, actions, item_cursor_factory, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts)
  local tbl = {
    _all_items = {},
    _action_name = opts.action_name,
    _is_valid = opts.is_valid,
    _actions = actions,
    _item_cursor_row = consumer_ctx.item_cursor_row,
    _item_cursor_factory = item_cursor_factory,
    _on_row_changed = callbacks.on_row_changed,
  }
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto.core.consumer_events")

local handlers = {
  --- @param self ThettoImmediate
  [consumer_events.all.items_changed] = function(self, items, _)
    self._all_items = items
  end,
  --- @param self ThettoImmediate
  [consumer_events.all.source_completed] = function(self)
    local item_cursor = self._item_cursor_factory(self._all_items)
    local row = item_cursor:apply(self._item_cursor_row, #self._all_items)
    local item = self._all_items[row]
    if not self._is_valid(item) then
      return require("thetto.vendor.promise").resolve()
    end

    self._item_cursor_row = row
    self._on_row_changed(row)

    local action_item_groups = require("thetto.util.action").grouping({ item }, {
      action_name = self._action_name,
      actions = self._actions,
    })
    return require("thetto.core.executor").execute(action_item_groups)
  end,
  [consumer_events.all.source_error] = function(_, err)
    vim.notify(require("thetto.vendor.misclib.message").wrap(err), vim.log.levels.WARN)
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
