--- @class ThettoUi
--- @field _item_list ThettoUiItemList
--- @field _inputter ThettoUiInputter
local Ui = {}
Ui.__index = Ui

function Ui.new(consumer_ctx, filters, callbacks)
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
  return setmetatable(tbl, Ui)
end

local consumer_events = require("thetto2.core.consumer_events")

local handlers = {
  --- @param self ThettoUi
  [consumer_events.all.items_changed] = vim.schedule_wrap(function(self, items)
    self._item_list:redraw_list(items)
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
