local consumer_events = require("thetto2.core.consumer_events")

--- @class ThettoCollector
--- @field _all_items table
--- @field _source_ctx table
--- @field _pipeline_ctx table
--- @field _subscription table
--- @field _item_cursor_row integer
--- @field _consumer ThettoConsumer
--- @field _pipeline ThettoPipeline
local Collector = {}
Collector.__index = Collector

function Collector.new(source, pipeline, ctx_key, consumer_factory, item_cursor_factory)
  local tbl = {
    _source = source,
    _pipeline = pipeline,
    _consumer_factory = consumer_factory,
    _item_cursor_factory = item_cursor_factory,
    _ctx_key = ctx_key,

    _all_items = {},
    _pipeline_ctx = require("thetto2.core.pipeline_context").new({}),
    _source_ctx = require("thetto2.core.source_context").new(source, {
      is_interactive = pipeline:has_source_input(),
    }),
    _subscription = nil,
    _consumer = nil,
    _item_cursor_row = 1,
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self)
  local subscriber = self:_create_subscriber()
  local consumer = self:_create_consumer()
  consumer:consume(consumer_events.source_started(self._source.name, self._source_ctx))
  return self:_start(subscriber, consumer), consumer
end

function Collector.restart(self, consumer, source_input)
  self:_stop()

  self._all_items = {}
  self._source_ctx = require("thetto2.core.source_context").new(self._source, source_input)
  local subscriber = self:_create_subscriber()

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
  local observable = require("thetto2.vendor.misclib.observable").new(subscriber)
  return require("thetto2.vendor.promise").new(function(resolve, reject)
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
  local items, pipeline_highlight = self._pipeline:apply(self._pipeline_ctx, self._all_items)
  self._consumer:consume(consumer_events.items_changed(items, #self._all_items, pipeline_highlight))
end

function Collector._create_subscriber(self)
  local subscriber_or_items = self._source.collect(self._source_ctx)
  if type(subscriber_or_items) == "function" then
    return subscriber_or_items
  end

  if type(subscriber_or_items.next) == "function" then
    -- promise case
    return function(observer)
      subscriber_or_items
        :next(function(result)
          if type(result) == "function" then
            -- promise returns subscriber case
            result(observer)
            return
          end

          -- promise returns items case
          observer:next(result)
          observer:complete(result)
        end)
        :catch(function(err)
          observer:error(err)
        end)
    end
  end

  return function(observer)
    observer:next(subscriber_or_items)
    observer:complete()
  end
end

--- @return ThettoConsumer
function Collector._create_consumer(self, consumer_factory)
  consumer_factory = consumer_factory or self._consumer_factory

  local callbacks = {
    on_change = function(pipeline_ctx)
      if not pipeline_ctx then
        return
      end
      self._pipeline_ctx = pipeline_ctx

      if pipeline_ctx.source_input.pattern then
        return self:restart(self._consumer, pipeline_ctx.source_input)
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
  return consumer_factory(consumer_ctx, self._source, self._pipeline, callbacks)
end

return Collector
