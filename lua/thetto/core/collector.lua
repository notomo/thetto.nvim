local consumer_events = require("thetto.core.consumer_events")

--- @class ThettoCollector
--- @field _all_items table
--- @field _source_ctx table
--- @field _subscription table
--- @field _inputs table
--- @field _item_cursor_row integer
--- @field _consumer ThettoConsumer
--- @field _pipeline ThettoPipeline
local Collector = {}
Collector.__index = Collector

--- @param pipeline ThettoPipeline
function Collector.new(source, pipeline, ctx_key, consumer_factory, item_cursor_factory, source_bufnr, actions)
  local source_ctx =
    require("thetto.core.source_context").new(source, source_bufnr, pipeline:initial_source_input_pattern())

  local tbl = {
    _source = source,
    _pipeline = pipeline,
    _consumer_factory = consumer_factory,
    _item_cursor_factory = item_cursor_factory,
    _ctx_key = ctx_key,
    _source_bufnr = source_bufnr,

    _all_items = {},
    _inputs = {},
    _source_ctx = source_ctx,
    _subscription = nil,
    _consumer = nil,
    _item_cursor_row = 1,
    _actions = actions,
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self)
  local subscriber = require("thetto.core.source_subscriber").new(self._source, self._source_ctx)

  local events = {}
  local skeleton_consumer = self:_create_consumer(function()
    return require("thetto.handler.consumer.skeleton").new(events)
  end)

  local promise = self:_start(subscriber, skeleton_consumer)

  local consumer = self:_create_consumer()
  self._consumer = consumer
  for _, event in ipairs(events) do
    consumer:consume(unpack(event))
  end

  return promise, consumer
end

--- @param consumer ThettoConsumer
--- @param source_input_pattern string?
function Collector.restart(self, consumer, source_input_pattern)
  self:_stop()

  self._all_items = {}
  self._source_ctx = require("thetto.core.source_context").new(
    self._source,
    self._source_bufnr,
    source_input_pattern or self._pipeline:initial_source_input_pattern()
  )
  local subscriber = require("thetto.core.source_subscriber").new(self._source, self._source_ctx)

  consumer:consume(consumer_events.source_started(self._source.name, self._source_ctx))
  return self:_start(subscriber, consumer)
end

function Collector.replay(self, consumer_factory, item_cursor_factory)
  item_cursor_factory = item_cursor_factory or self._item_cursor_factory

  self:_stop()

  local all_items = self._all_items
  local item_cursor = item_cursor_factory(all_items)
  local subscriber = function(observer)
    observer:next(all_items)
    observer:complete()
  end
  self._all_items = {}

  local consumer = self:_create_consumer(consumer_factory)
  return self:_start(subscriber, consumer, item_cursor), consumer
end

function Collector._start(self, subscriber, consumer, default_item_cursor)
  self._consumer = consumer

  local default_kind_name = self._source.kind_name or "base"
  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  return require("thetto.vendor.promise").new(function(resolve, reject)
    self._subscription = observable:subscribe({
      next = function(items)
        local count = #self._all_items
        for i, item in ipairs(items) do
          item.index = count + i
          item.kind_name = item.kind_name or default_kind_name
        end
        vim.list_extend(self._all_items, items)

        self:_run_pipeline()
      end,
      complete = function()
        local item_cursor = default_item_cursor or self._item_cursor_factory(self._all_items)
        resolve(self._consumer:consume(consumer_events.source_completed(item_cursor)))
      end,
      error = function(err)
        reject(self._consumer:consume(consumer_events.source_error(err)))
      end,
    })
  end)
end

function Collector._stop(self)
  return self._subscription and self._subscription:unsubscribe()
end

function Collector._run_pipeline(self)
  local items, pipeline_highlight = self._pipeline:apply(self._source_ctx, self._all_items, self._inputs)
  self._consumer:consume(consumer_events.items_changed(items, #self._all_items, pipeline_highlight))
end

--- @return ThettoConsumer
function Collector._create_consumer(self, consumer_factory)
  consumer_factory = consumer_factory or self._consumer_factory

  local callbacks = {
    on_change = function(inputs, source_input_pattern)
      self._inputs = inputs

      if source_input_pattern then
        return self:restart(self._consumer, source_input_pattern)
      end
      return self:_run_pipeline()
    end,
    on_row_changed = function(row)
      self._item_cursor_row = row
    end,
    on_discard = function()
      self:_stop()
    end,
  }
  local consumer_ctx = {
    ctx_key = self._ctx_key,
    source_ctx = self._source_ctx,
    item_cursor_row = self._item_cursor_row,
  }
  return consumer_factory(consumer_ctx, self._source, self._pipeline, callbacks, self._actions)
end

return Collector
