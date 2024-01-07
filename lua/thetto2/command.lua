local M = {}

function M.start(source, raw_opts)
  local opts = require("thetto2.core.option").new_start_opts(raw_opts)

  local pipeline = opts.pipeline_factory()
  local ctx_key = require("thetto2.core.context").new_key()
  local collector =
    require("thetto2.core.collector").new(source, pipeline, ctx_key, opts.consumer_factory, opts.item_cursor_factory)

  local actions = vim.tbl_deep_extend("force", source.actions or {}, opts.actions)

  local promise, consumer = collector:start()
  require("thetto2.core.context").set(ctx_key, {
    collector = collector,
    consumer = consumer,
    actions = actions,
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
  local opts = require("thetto2.core.option").new_resume_opts(raw_opts)

  local ctx, old_ctx = require("thetto2.core.context").resume(opts.offset)
  if not ctx then
    return
  end
  if old_ctx then
    old_ctx.consumer:call("quit", {})
  end

  local promise, consumer = ctx.collector:replay(opts.consumer_factory, opts.item_cursor_factory)
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

  return require("thetto2.core.executor").execute(action_item_groups)
end

function M.get()
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  local items = ctx.consumer:get_items()
  local metadata = {
    actions = ctx.actions,
  }
  return items, metadata
end

function M.call_consumer(action_name, opts)
  local ctx = require("thetto2.core.context").get()
  if type(ctx) == "string" then
    return ctx
  end

  return ctx.consumer:call(action_name, opts)
end

function M.setup_store(name, opts)
  local store, err = require("thetto2.core.store").new(name)
  if err then
    error(err)
  end
  store.start(opts)
end

return M
