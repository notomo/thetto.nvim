local M = {}

function M.start(source, raw_opts)
  local opts = require("thetto2.core.option").new_start_opts(raw_opts)

  local pipeline = opts.pipeline_factory()
  local ctx_key = require("thetto2.core.context").new_key()
  local collector = require("thetto2.core.collector").new(source, pipeline, ctx_key, opts.consumer_factory)
  local executor = require("thetto2.core.executor").new()

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

  return ctx.collector:restart(ctx.consumer)
end

function M.resume(raw_opts)
  local ctx = require("thetto2.core.context").resume()
  if not ctx then
    return
  end

  local promise, consumer = ctx.collector:replay()
  ctx:update({ consumer = consumer })
  return promise
end

function M.execute(action_item_groups, raw_opts)
  local opts = require("thetto2.core.option").new_execute_opts(raw_opts)

  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  if opts.quit then
    ctx.consumer:call("quit", {})
  end

  return ctx.executor:execute(action_item_groups)
end

function M.get()
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  return ctx.consumer:get_items()
end

function M.call_consumer(action_name, opts)
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  return ctx.consumer:call(action_name, opts)
end

return M
