local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.new(source)
  local tbl = {
    _source = source,
    _subscription = nil,
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self, consumer)
  local subscriber_or_items = self._source.collect()

  local subscriber
  if type(subscriber_or_items) == "table" then
    subscriber = function(observer)
      observer:next(subscriber_or_items)
      observer:complete()
    end
  else
    subscriber = subscriber_or_items
  end

  consumer:start()

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  return require("thetto.vendor.promise").new(function(resolve, reject)
    self._subscription = observable:subscribe({
      next = function(items)
        consumer:consume(items)
      end,
      error = function(e)
        reject(consumer:error(e))
      end,
      complete = function()
        resolve(consumer:complete())
      end,
    })
  end)
end

function Collector.stop(self)
  return self._subscription and self._subscription:unsubscribe()
end

function Collector.finished(self)
  return self._subscription and self._subscription:closed()
end

function M.factory(source)
  return function()
    return Collector.new(source)
  end
end

return M
