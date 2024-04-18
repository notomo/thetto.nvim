local consumer_events = require("thetto.core.consumer_events")

--- @class ThettoCollectorRun
--- @field source_ctx ThettoSourceContext
--- @field source_err string?
--- @field _pipeline ThettoPipeline
--- @field _consumer ThettoConsumer
--- @field private _inputs table
--- @field _subscription table
--- @field _promise table
local M = {}
M.__index = M

function M.new(subscriber, consumer, pipeline, source_ctx, source_name, default_kind_name, inputs)
  default_kind_name = default_kind_name or "base"

  local tbl = {
    source_ctx = source_ctx,
    source_err = nil,

    _consumer = consumer,
    _pipeline = pipeline,
    _source_name = source_name,
    _default_kind_name = default_kind_name,

    _all_items = {},
    _inputs = inputs,
  }
  local self = setmetatable(tbl, M)

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  self._promise = require("thetto.vendor.promise").new(function(resolve, reject)
    self._subscription = observable:subscribe({
      next = function(items)
        local count = #self._all_items
        for i, item in ipairs(items) do
          item.index = count + i
          item.kind_name = item.kind_name or default_kind_name
        end
        vim.list_extend(self._all_items, items)

        self:run_pipeline()
      end,
      complete = function()
        resolve(self._consumer:consume(consumer_events.source_completed()))
      end,
      error = function(err)
        self.source_err = err
        reject(self._consumer:consume(consumer_events.source_error(err)))
      end,
    })
  end)

  return self
end

function M.run_pipeline(self)
  local items, pipeline_highlight = self._pipeline:apply(self.source_ctx, self._all_items, self._inputs)
  self._consumer:consume(consumer_events.items_changed(items, #self._all_items, pipeline_highlight))
end

function M.apply_inputs(self, inputs)
  self._inputs = inputs
end

function M.stop(self)
  return self._subscription and self._subscription:unsubscribe()
end

function M.promise(self)
  return self._promise
end

function M.restart(self, subscriber, source_ctx)
  self:stop()

  self._consumer:consume(consumer_events.source_started(self._source_name, source_ctx))

  return M.new(
    subscriber,
    self._consumer,
    self._pipeline,
    source_ctx,
    self._source_name,
    self._default_kind_name,
    self._inputs
  )
end

function M.resume(self, consumer)
  self:stop()

  local subscriber = function(observer)
    if self.source_err then
      observer:error(self.source_err)
      return
    end
    observer:next(self._all_items)
    observer:complete()
  end

  return M.new(
    subscriber,
    consumer,
    self._pipeline,
    self.source_ctx,
    self._source_name,
    self._default_kind_name,
    self._inputs
  )
end

return M
