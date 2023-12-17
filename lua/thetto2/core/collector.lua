local Collector = {}
Collector.__index = Collector

function Collector.new(source, pipeline, ctx_key, consumer_factory)
  local tbl = {
    _source = source,
    _pipeline = pipeline,
    _consumer_factory = consumer_factory,
    _ctx_key = ctx_key,

    _all_items = {},
    _pipeline_ctx = require("thetto2.core.pipeline_context").new(),
    _source_ctx = require("thetto2.core.source_context").new(source),
    _subscription = nil,
    _consumer = nil,
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self)
  local subscriber = self:_create_subscriber()
  local consumer = self:_create_consumer()
  return self:_start(subscriber, consumer)
end

function Collector.restart(self)
  self:_stop()

  self._all_items = {}
  self._source_ctx = require("thetto2.core.source_context").new(self._source)
  local subscriber = self:_create_subscriber()

  return self:_start(subscriber, self._consumer)
end

function Collector.replay(self)
  self:_stop()

  local all_items = self._all_items
  local subscriber = function(observer)
    observer:next(all_items)
    observer:complete()
  end
  self._all_items = {}

  local consumer = self:_create_consumer()
  return self:_start(subscriber, consumer)
end

function Collector._start(self, subscriber, consumer)
  self._consumer = consumer

  local observable = require("thetto2.vendor.misclib.observable").new(subscriber)
  return require("thetto2.vendor.promise").new(function(resolve, reject)
    self._subscription = observable:subscribe({
      next = function(items)
        vim.list_extend(self._all_items, items)
        self:_run_pipeline(self._pipeline_ctx)
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

function Collector._stop(self)
  return self._subscription and self._subscription:unsubscribe()
end

function Collector._run_pipeline(self, pipeline_ctx)
  self._pipeline_ctx = pipeline_ctx
  self._consumer:consume(self._pipeline:apply(pipeline_ctx, self._all_items))
end

function Collector._create_subscriber(self)
  local subscriber_or_items = self._source.collect(self._source_ctx)
  if type(subscriber_or_items) == "function" then
    return subscriber_or_items
  end

  return function(observer)
    observer:next(subscriber_or_items)
    observer:complete()
  end
end

function Collector._create_consumer(self)
  local callbacks = {
    on_change = function(pipeline_ctx_factory)
      local pipeline_ctx = pipeline_ctx_factory()
      self:_run_pipeline(pipeline_ctx)
    end,
    on_discard = function()
      self:_stop()
    end,
  }
  local consumer_ctx = {
    ctx_key = self._ctx_key,
    cwd = self._source_ctx.cwd,
  }
  return self._consumer_factory(consumer_ctx, self._pipeline, callbacks)
end

return Collector
