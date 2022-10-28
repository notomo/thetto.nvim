local SourceResult = {}
SourceResult.__index = SourceResult

local _new = function(subscriber, promise)
  local tbl = {
    _subscriber = subscriber,
    _all_items = {},
    _promise = promise,
  }
  return setmetatable(tbl, SourceResult)
end

function SourceResult.new(subscriber_or_items)
  vim.validate({
    subscriber_or_items = { subscriber_or_items, { "table", "function" } },
  })

  if type(subscriber_or_items) == "function" then
    return _new(subscriber_or_items)
  end
  if type(subscriber_or_items.next) == "function" then
    return _new(nil, subscriber_or_items)
  end

  local all_items = subscriber_or_items or {}
  if #all_items == 0 then
    return nil, "empty"
  end

  return _new(function(observer)
    observer:next(all_items)
    observer:complete()
  end)
end

function SourceResult.zero()
  return _new(function() end)
end

function SourceResult.start(self, raw_observer)
  if self._subscriber then
    local observable = require("thetto.vendor.misclib.observable").new(self._subscriber)
    self._subscription = observable:subscribe(raw_observer)
    return
  end

  self._promise
    :next(function(subscriber_or_items)
      local result, err = SourceResult.new(subscriber_or_items)
      if err then
        return raw_observer.error(err)
      end
      result:start(raw_observer)
      self._subscription = result._subscription
    end)
    :catch(function(err)
      raw_observer.error(err)
    end)
end

function SourceResult.discard(self)
  return self._subscription and self._subscription:unsubscribe()
end

function SourceResult.finished(self)
  return self._subscription and self._subscription:closed()
end

function SourceResult.iter(self)
  return ipairs(self._all_items)
end

function SourceResult.count(self)
  return #self._all_items
end

function SourceResult.append(self, items)
  local len = #self._all_items
  for i, item in ipairs(items) do
    item.index = len + i
  end
  vim.list_extend(self._all_items, items)
end

function SourceResult.apply_selected(self, items)
  for _, item in items:iter() do
    if item.selected ~= nil then
      self._all_items[item.index].selected = item.selected
    end
  end
end

return SourceResult
