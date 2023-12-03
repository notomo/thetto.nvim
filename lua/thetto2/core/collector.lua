local M = {}

local Collector = {}
Collector.__index = Collector

function Collector.new(source, pipeline, consumer_factory)
  local tbl = {
    _source = source,
    _pipeline = pipeline,
    _consumer_factory = consumer_factory,

    _subscription = nil,
    _consumer = nil,
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self)
  return self:_start(nil)
end

function Collector.restart(self)
  self:_stop()
  return self:_start(self._consumer)
end

function Collector._start(self, consumer)
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

  local on_change = function(...)
    self:_run_pipeline(...)
  end
  local on_discard = function()
    self:_stop()
  end
  self._consumer = consumer or self._consumer_factory(self._pipeline, on_change, on_discard)

  local observable = require("thetto2.vendor.misclib.observable").new(subscriber)
  return require("thetto2.vendor.promise").new(function(resolve, reject)
    self._subscription = observable:subscribe({
      next = function(items)
        self._consumer:consume(self._pipeline:apply(items))
      end,
      complete = function()
        resolve(self._consumer:complete())
      end,
      error = function(e)
        reject(self._consumer:on_error(e))
      end,
    })
  end)
end

function Collector.finished(self)
  return self._subscription and self._subscription:closed()
end

function Collector._stop(self)
  return self._subscription and self._subscription:unsubscribe()
end

function Collector._run_pipeline(self, row, get_lines)
  return nil
end

function M.factory(source, pipeline, consumer_factory)
  return function()
    return Collector.new(source, pipeline, consumer_factory)
  end
end

return M
