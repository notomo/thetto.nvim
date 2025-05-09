local M = {}

local handle_error = function(promise)
  return promise:catch(function(err)
    if not err then
      return
    end
    require("thetto.lib.message").warn(err)
  end)
end

function M.start(source, raw_opts)
  local opts = require("thetto.core.option").new_start_opts(source, raw_opts)

  local ctx_key = (source.key or require("thetto.util.source_key").unique())({
    source = source,
  })
  require("thetto.core.context").expire(ctx_key)

  local collector = require("thetto.core.collector").new(
    source,
    opts.pipeline,
    ctx_key,
    opts.consumer_factory,
    opts.item_cursor_factory,
    opts.source_bufnr,
    opts.source_window_id,
    opts.actions
  )

  local promise, consumer, source_errored = collector:start()
  if source.can_resume ~= false and not source_errored then
    require("thetto.core.context").set(ctx_key, {
      collector = collector,
      consumer = consumer,
      actions = opts.actions,
    })
  end
  return handle_error(promise)
end

function M.reload(bufnr)
  local ctx = require("thetto.core.context").get(bufnr)
  if type(ctx) == "string" then
    local err = ctx
    error(require("thetto.lib.message").wrap(err), 0)
  end

  local promise = ctx.collector:restart()
  return handle_error(promise)
end

function M.resume(raw_opts)
  local opts = require("thetto.core.option").new_resume_opts(raw_opts)

  local ctx, old_ctx = require("thetto.core.context").resume(opts.offset)
  if not ctx then
    return handle_error(require("thetto.vendor.promise").reject("no context to resume"))
  end
  if old_ctx then
    -- don't call update_used_at() to loop resume()
    old_ctx.consumer:call("quit", {})
  end

  local promise, consumer = ctx.collector:resume(opts.consumer_factory, opts.item_cursor_factory)
  ctx:update({ consumer = consumer })
  return handle_error(promise)
end

function M.execute(action_item_groups, raw_opts)
  local opts = require("thetto.core.option").new_execute_opts(raw_opts)

  if opts.quit then
    M.quit()
  end

  local promise = require("thetto.core.executor").execute(action_item_groups)
  return handle_error(promise)
end

function M.get()
  local ctx = require("thetto.core.context").get()
  if type(ctx) == "string" then
    local err = ctx
    error(require("thetto.lib.message").wrap(err), 0)
  end

  local items = ctx.consumer:get_items()
  local metadata = {
    actions = ctx.actions,
  }
  return items, metadata
end

function M.call_consumer(action_name, opts)
  local ctx = require("thetto.core.context").get()
  if type(ctx) == "string" then
    local err = ctx
    error(require("thetto.lib.message").wrap(err), 0)
  end
  return ctx.consumer:call(action_name, opts)
end

function M.quit()
  local ctx = require("thetto.core.context").get()
  if type(ctx) == "string" then
    return require("thetto.handler.consumer.ui").quit_fallback()
  end

  ctx:update_used_at()

  return ctx.consumer:call("quit", {})
end

function M.setup_store(name, raw_opts)
  local store = require("thetto.core.store").new(name)
  if type(store) == "string" then
    local err = store
    error(require("thetto.lib.message").wrap(err), 0)
  end

  store.setup(raw_opts)
end

return M
