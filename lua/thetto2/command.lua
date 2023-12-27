local M = {}

function M.start(source, raw_opts)
  local opts = require("thetto2.core.option").new_start_opts(raw_opts)

  local pipeline = opts.pipeline_factory()
  local ctx_key = require("thetto2.core.context").new_key()
  local collector = require("thetto2.core.collector").new(source, pipeline, ctx_key, opts.consumer_factory)
  local executor = require("thetto2.core.executor").new(opts.kinds)

  local promise, consumer = collector:start()
  require("thetto2.core.context").set(ctx_key, {
    collector = collector,
    executor = executor,
    consumer = consumer,
  })
  return promise
end

function M.reload(bufnr)
  local ctx = require("thetto2.core.context").get(bufnr)
  if type(ctx) == "string" then
    return ctx
  end

  return ctx.collector:restart()
end

function M.resume(raw_opts)
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  local promise, consumer = ctx.collector:replay()
  ctx:update({ consumer = consumer })
  return promise
end

function M.execute(raw_opts)
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  local selected_items = require("thetto2.core.items.selector").extract_selected(ctx.items)
  return ctx.executor:execute_action(selected_items)
end

function M.get()
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  return require("thetto2.core.items.selector").extract_selected(ctx.items)
end

function M.call_consumer(action_name, opts)
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  return ctx.consumer:call(action_name, opts)
end

return M
