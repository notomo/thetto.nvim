--- @class ThettoUi
--- @field _item_list ThettoUiItemList
--- @field _inputter ThettoUiInputter
--- @field _sidecar ThettoUiSidecar
--- @field _closer ThettoUiCloser
local Ui = {}
Ui.__index = Ui

function Ui.new(consumer_ctx, filters, callbacks, has_sidecar, sidecar_action)
  local closer = require("thetto2.handler.consumer.ui.closer").new()
  local layout = require("thetto2.handler.consumer.ui.layout").new(has_sidecar, filters)

  local item_list = require("thetto2.handler.consumer.ui.item_list").open(
    consumer_ctx.ctx_key,
    consumer_ctx.cwd,
    closer,
    layout.item_list
  )

  local inputter = require("thetto2.handler.consumer.ui.inputter").open(
    consumer_ctx.ctx_key,
    consumer_ctx.cwd,
    closer,
    layout.inputter,
    callbacks.on_change
  )

  local sidecar = require("thetto2.handler.consumer.ui.sidecar").open(consumer_ctx.ctx_key, closer, layout.sidecar)

  closer:setup(function()
    local current_window_id = vim.api.nvim_get_current_win()
    item_list:close(current_window_id)
    inputter:close(current_window_id)
    sidecar:close()
    callbacks.on_discard()
  end)

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
    _sidecar = sidecar,
    _closer = closer,
  }
  return setmetatable(tbl, Ui)
end

local consumer_events = require("thetto2.core.consumer_events")

local handlers = {
  --- @param self ThettoUi
  [consumer_events.all.items_changed] = vim.schedule_wrap(function(self, items, all_items_count)
    self._item_list:redraw_list(items, all_items_count)
  end),
  --- @param self ThettoUi
  [consumer_events.all.source_started] = vim.schedule_wrap(function(self, source_name)
    self._item_list:redraw_footer(source_name, "running")
  end),
  --- @param self ThettoUi
  [consumer_events.all.source_completed] = vim.schedule_wrap(function(self)
    self._item_list:redraw_footer(nil, "")
  end),
  [consumer_events.all.source_error] = function(_, err)
    error(err)
  end,
}

function Ui.consume(self, event_name, ...)
  local handler = handlers[event_name]
  if not handler then
    return
  end
  return handler(self, ...)
end

local actions = {
  --- @param self ThettoUi
  move_to_input = function(self)
    self._inputter:enter()
  end,
  --- @param self ThettoUi
  move_to_list = function(self)
    self._item_list:enter()
  end,
  --- @param self ThettoUi
  quit = function(self)
    self._closer:execute()
  end,
  --- @param self ThettoUi
  toggle_selection = function(self)
    self._item_list:toggle_selection()
  end,
}

function Ui.call(self, action_name, opts)
  local action = actions[action_name]
  if not action then
    return
  end
  return action(self)
end

function Ui.get_items(self)
  return self._item_list:get_items()
end

return Ui
