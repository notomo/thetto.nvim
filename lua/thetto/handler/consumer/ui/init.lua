local UI = {}
UI.__index = UI

function UI.new()
  local tbl = {
    _all_items = {},
  }
  return setmetatable(tbl, UI)
end

function UI.start(self)
  return nil
end

function UI.consume(self, items)
  vim.list_extend(self._all_items, items)
end

function UI.on_error(self, err)
  error(err)
end

function UI.complete(self)
  return self._all_items
end

return UI
