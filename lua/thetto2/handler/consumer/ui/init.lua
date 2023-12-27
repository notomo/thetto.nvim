--- @class ThettoUi
--- @field _item_list ThettoUiItemList
--- @field _inputter ThettoUiInputter
--- @field _sidecar ThettoUiSidecar
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
    item_list:close()
    inputter:close()
    sidecar:close()
    callbacks.on_discard()
  end)

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
    _sidecar = sidecar,
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

return Ui
