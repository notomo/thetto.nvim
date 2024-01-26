--- @class ThettoCollector
--- @field _pipeline ThettoPipeline
--- @field _current_run ThettoCollectorRun?
--- @field _item_cursor_row integer
local Collector = {}
Collector.__index = Collector

--- @param pipeline ThettoPipeline
--- @return ThettoCollector
function Collector.new(
  source,
  pipeline,
  ctx_key,
  consumer_factory,
  item_cursor_factory,
  source_bufnr,
  source_window_id,
  actions
)
  local tbl = {
    _source = source,
    _pipeline = pipeline,
    _consumer_factory = consumer_factory,
    _item_cursor_factory = item_cursor_factory,
    _ctx_key = ctx_key,
    _source_bufnr = source_bufnr,
    _source_window_id = source_window_id,
    _actions = actions,

    _current_run = nil,

    _item_cursor_row = 1, -- consumer_shared_state
  }
  return setmetatable(tbl, Collector)
end

function Collector.start(self)
  local source_ctx = require("thetto.core.source_context").new(
    self._source,
    self._source_bufnr,
    self._source_window_id,
    self._pipeline:initial_source_input_pattern()
  )

  local subscriber, source_errored = require("thetto.core.source_subscriber").new(self._source, source_ctx)
  local consumer = self:_create_consumer(source_ctx, source_errored)
  self._current_run = require("thetto.core.collector_run").new(
    subscriber,
    consumer,
    self._pipeline,
    source_ctx,
    self._item_cursor_factory,
    self._source.name,
    self._source.kind_name,
    {}
  )
  return self._current_run:promise(), consumer
end

--- @param source_input_pattern string?
function Collector.restart(self, source_input_pattern)
  local source_ctx = require("thetto.core.source_context").new(
    self._source,
    self._source_bufnr,
    self._source_window_id,
    source_input_pattern or self._pipeline:initial_source_input_pattern(),
    self._current_run.source_ctx.store_to_restart
  )

  local subscriber, _ = require("thetto.core.source_subscriber").new(self._source, source_ctx)
  self._current_run = self._current_run:restart(subscriber, source_ctx)
  return self._current_run:promise()
end

function Collector.resume(self, consumer_factory, item_cursor_factory)
  local source_errored = self._current_run.source_err ~= nil
  local consumer = self:_create_consumer(self._current_run.source_ctx, source_errored, consumer_factory)
  self._current_run = self._current_run:resume(consumer, item_cursor_factory or self._item_cursor_factory)
  return self._current_run:promise(), consumer
end

--- @param source_ctx ThettoSourceContext
--- @return ThettoConsumer
function Collector._create_consumer(self, source_ctx, source_errored, consumer_factory)
  consumer_factory = consumer_factory or self._consumer_factory

  local callbacks = {
    on_change = function(inputs, source_input_pattern)
      self._current_run:apply_inputs(inputs)

      if source_input_pattern then
        return self:restart(source_input_pattern)
      end
      return self._current_run:run_pipeline()
    end,
    on_row_changed = function(row)
      self._item_cursor_row = row
    end,
    on_discard = function()
      self._current_run:stop()
    end,
  }
  local consumer_ctx = {
    ctx_key = self._ctx_key,
    source_ctx = source_ctx,
    source_errored = source_errored,
    item_cursor_row = self._item_cursor_row,
  }
  return consumer_factory(consumer_ctx, self._source, self._pipeline, callbacks, self._actions)
end

return Collector
