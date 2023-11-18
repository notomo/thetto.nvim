local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.new(source, pipeline)
  local tbl = {
    _source = source,
    _pipeline = pipeline,
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
        consumer:consume(self._pipeline(items))
      end,
      complete = function()
        resolve(consumer:complete())
      end,
      error = function(e)
        reject(consumer:on_error(e))
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

function M.factory(source, pipeline)
  return function()
    return Collector.new(source, pipeline)
  end
end

return M
