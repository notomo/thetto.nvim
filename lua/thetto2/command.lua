local M = {}

function M.start(source, raw_opts)
  local opts = require("thetto2.core.option").new_start_opts(raw_opts)

  local pipeline = opts.pipeline_factory()
  local collector_factory = require("thetto2.core.collector").factory(source, pipeline, opts.consumer_factory)
  local collector = collector_factory()

  local executor = require("thetto2.core.executor").new(opts.kinds)

  require("thetto2.core.context").new({
    collector_factory = collector_factory,
    collector = collector,
    executor = executor,
  })

  return collector:start()
end

function M.reload(bufnr)
  local ctx, ctx_err = require("thetto2.core.context").get(bufnr)
  if ctx_err then
    return ctx_err
  end
  return ctx.collector:restart()
end

function M.resume(raw_opts)
  local ctx, ctx_err = require("thetto2.core.context").get()
  if ctx_err then
    return ctx_err
  end

  return ctx.consume(ctx.items)
end

function M.execute(raw_opts)
  local ctx, ctx_err = require("thetto2.core.context").get()
  if ctx_err then
    return ctx_err
  end

  local selected_items = require("thetto2.core.items.selector").extract_selected(ctx.items)
  return ctx.executor:execute_action(selected_items)
end

function M.get()
  local ctx, ctx_err = require("thetto2.core.context").get()
  if ctx_err then
    return ctx_err
  end

  return require("thetto2.core.items.selector").extract_selected(ctx.items)
end

return M
