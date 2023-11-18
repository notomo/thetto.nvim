local M = {}

function M.start(source, raw_opts)
  local opts = require("thetto.core.option").new_start_opts(raw_opts)

  local collector_factory = require("thetto.core.collector").factory(source, opts.pipeline)
  local collector = collector_factory()
  local consumer = opts.consumer_factory()
  local executor = require("thetto.core.executor").new(opts.kinds)

  local ctx = require("thetto.core.context").new({
    collector_factory = collector_factory,
    collector = collector,
    consumer = consumer,
    executor = executor,
  })

  local on_discard = function()
    collector:stop()
  end

  return collector:start(ctx.consumer)
end

function M.reload(bufnr)
  local ctx, ctx_err = require("thetto.core.context").get(bufnr)
  if ctx_err then
    return ctx_err
  end

  ctx.collector:stop()

  local collector = ctx.collector_factory()
  ctx:update({ collector = collector })

  return collector:start(ctx.consumer)
end

function M.resume(raw_opts)
  local ctx, ctx_err = require("thetto.core.context").get()
  if ctx_err then
    return ctx_err
  end

  return ctx.consume(ctx.items)
end

function M.execute(raw_opts)
  local ctx, ctx_err = require("thetto.core.context").get()
  if ctx_err then
    return ctx_err
  end

  local selected_items = require("thetto.core.items.selector").extract_selected(ctx.items)
  return ctx.executor:execute_action(selected_items)
end

function M.get()
  local ctx, ctx_err = require("thetto.core.context").get()
  if ctx_err then
    return ctx_err
  end

  return require("thetto.core.items.selector").extract_selected(ctx.items)
end

return M
