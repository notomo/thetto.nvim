local UI = {}
UI.__index = UI

function UI.new(filters, ctx_key, callbacks)
  -- close old ui on the same tabpage

  local closer = require("thetto2.handler.consumer.ui.closer").new()
  local layout = require("thetto2.handler.consumer.ui.layout").new()
  local item_list = require("thetto2.handler.consumer.ui.item_list").open(ctx_key, closer, layout)
  local inputter =
    require("thetto2.handler.consumer.ui.inputter").open(ctx_key, closer, layout, filters, callbacks.on_change)

  closer:setup(function()
    item_list:close()
    inputter:close()
    callbacks.on_discard()
  end)

  inputter:enter()

  -- setup on moved autocmd

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
  }
  return setmetatable(tbl, UI)
end

function UI.consume(self, items)
  self._item_list:redraw(items)
end

function UI.on_error(self, err)
  error(err)
end

function UI.complete(self) end

return UI
