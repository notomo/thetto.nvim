local Subscription = {}
Subscription.__index = Subscription

function Subscription.new(observer, subscriber)
  local tbl = {
    _observer = observer,
    _on_unsubscribe = function() end,
  }
  local self = setmetatable(tbl, Subscription)

  observer.start(self)

  if self:closed() then
    return self
  end

  local subscription_observer = {
    next = function(_, ...)
      if self:closed() then
        return
      end
      self._observer.next(...)
    end,

    error = function(_, ...)
      if self:closed() then
        return
      end
      self._observer = nil
      observer.error(...)
      self:_cleanup()
    end,

    complete = function()
      if self:closed() then
        return
      end
      self._observer = nil
      observer.complete()
      self:_cleanup()
    end,

    closed = function()
      return self:closed()
    end,
  }

  local ok, result = pcall(subscriber, subscription_observer)
  if not ok then
    observer.error(result)
    return self
  end
  self._on_unsubscribe = result or self._on_unsubscribe

  if self:closed() then
    self:_cleanup()
  end
  return self
end

function Subscription._cleanup(self)
  if not self._on_unsubscribe then
    return
  end
  local on_unsubscribe = self._on_unsubscribe
  self._on_unsubscribe = nil
  on_unsubscribe()
end

function Subscription.unsubscribe(self)
  if self:closed() then
    return
  end
  self._observer = nil
  self:_cleanup()
end

function Subscription.closed(self)
  return self._observer == nil
end

local Observable = {}
Observable.__index = Observable

function Observable.new(subscriber)
  vim.validate({ subscriber = { subscriber, "function" } })
  local tbl = { _subscriber = subscriber }
  return setmetatable(tbl, Observable)
end

function Observable.subscribe(self, observer)
  vim.validate({ observer = { observer, "table" } })
  observer = {
    start = observer.start or function() end,
    next = observer.next or function() end,
    error = observer.error or function() end,
    complete = observer.complete or function() end,
  }
  return Subscription.new(observer, self._subscriber)
end

return Observable
