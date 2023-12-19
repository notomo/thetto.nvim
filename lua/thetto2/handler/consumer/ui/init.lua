local UI = {}
UI.__index = UI

function UI.new(consumer_ctx, filters, callbacks)
  local closer = require("thetto2.handler.consumer.ui.closer").new()
  local layout = require("thetto2.handler.consumer.ui.layout").new()
  local item_list =
    require("thetto2.handler.consumer.ui.item_list").open(consumer_ctx.ctx_key, consumer_ctx.cwd, closer, layout)
  local inputter = require("thetto2.handler.consumer.ui.inputter").open(
    consumer_ctx.ctx_key,
    consumer_ctx.cwd,
    closer,
    layout,
    filters,
    callbacks.on_change
  )

  closer:setup(function()
    item_list:close()
    inputter:close()
    callbacks.on_discard()
  end)

  -- setup on moved autocmd

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
  }
  return setmetatable(tbl, UI)
end

local consumer_events = require("thetto2.core.consumer_events")

local handlers = {
  [consumer_events.items_changed] = vim.schedule_wrap(function(self, items)
    self._item_list:redraw(items)
  end),
  [consumer_events.source_stared] = vim.schedule_wrap(function(self)
    self._item_list:redraw_status("running")
  end),
  [consumer_events.source_completed] = vim.schedule_wrap(function(self)
    self._item_list:redraw_status("")
  end),
  [consumer_events.source_error] = function(self, err)
    error(err)
  end,
}

function UI.consume(self, event_name, ...)
  local handler = handlers[event_name]
  if not handler then
    return
  end
  return handler(self, ...)
end

return UI
