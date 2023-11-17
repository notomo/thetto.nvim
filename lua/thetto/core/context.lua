local M = {}

local Context = {}
Context.__index = Context

function Context.new(fields)
  local tbl = {
    items = {},
    all_items = {},
  }
  local ctx = setmetatable(tbl, Context)
  ctx:update(fields)
  return ctx
end

function Context.update(self, fields)
  self.collector_factory = fields.collector_factory or self.collector_factory
  self.pipeline = fields.pipeline or self.pipeline
  self.consumer = fields.consumer or self.consumer
  self.executor = fields.executor or self.executor
  self.items = fields.items or self.items
  self.all_items = fields.all_items or self.all_items
  self.collector = fields.collector or self.collector
end

local _ctxs = {}

function M.set(fields)
  local ctx = Context.new(fields)
  table.insert(_ctxs, 1, ctx)
  return ctx
end

function M.get(bufnr)
  return nil
end

return M
