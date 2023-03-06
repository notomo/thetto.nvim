local M = {}

local Context = require("thetto.core.context")
local Promise = require("thetto.vendor.promise")

local _execute_action = function(ctx, action_name, raw_args)
  local args =
    require("thetto.core.argument").ExecuteArgs.new(action_name or ctx.collector.source.default_action, raw_args)
  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  local items = ctx.ui:selected_items(args.action_name, range)
  return ctx.executor
    :actions(items, ctx, args.action_name, args.fallback_actions, args.action_opts, args.allow_no_items)
    :catch(function(e)
      require("thetto.vendor.misclib.message").warn(e)
    end)
end

function M.start(source_name, raw_args)
  vim.validate({ source_name = { source_name, "string" } })

  local source_config
  source_name, source_config = require("thetto.core.option").resolve_alias(source_name)

  local args = require("thetto.core.argument").StartArgs.new(raw_args)
  local opts, source_opts, opts_err =
    require("thetto.core.option").Option.new(args.opts, args.source_opts, source_config)
  if opts_err ~= nil then
    require("thetto.vendor.misclib.message").warn(opts_err)
    return Promise.resolve()
  end

  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close()
  end

  local source, source_err = require("thetto.core.items.source").new(source_name, source_opts, opts)
  if source_err ~= nil then
    require("thetto.vendor.misclib.message").warn(source_err)
    return Promise.resolve()
  end
  local behaviors = source.behaviors

  local collector, err = require("thetto.core.collector").new(source)
  if err ~= nil then
    require("thetto.vendor.misclib.message").warn(err)
    return Promise.resolve()
  end

  local execute_opts = require("thetto.core.option").ExecuteOption.new(source_name, collector.source.actions)
  local executor =
    require("thetto.core.executor").new(collector.source.kind_name, args.action_opts, behaviors.action, execute_opts)
  local ui = require("thetto.view.ui").new(collector, behaviors.insert, behaviors.cwd)
  local ctx = Context.new(source_name, collector, ui, executor, behaviors.can_resume)

  local promise = Promise.new(function(resolve, reject)
    local start_err = collector:start(behaviors.pattern, resolve, reject)
    if start_err ~= nil then
      return reject(start_err)
    end

    local open_err = ui:open(behaviors.immediately, executor:auto(ctx, behaviors.auto))
    if err then
      return reject(open_err)
    end
    if behaviors.immediately then
      ui:close(nil, behaviors.immediately)
    end

    return collector:update()
  end):next(function()
    ui:scroll(behaviors.offset, behaviors.search_offset)
  end)

  if not behaviors.immediately then
    return promise:catch(function(e)
      require("thetto.vendor.misclib.message").warn(e)
    end)
  end

  return promise
    :next(function()
      return _execute_action(ctx, behaviors.action, { action_opts = args.action_opts })
    end)
    :catch(function(e)
      require("thetto.vendor.misclib.message").warn(e)
    end)
end

function M.reload(bufnr)
  return Promise.new(function(resolve, reject)
    local ctx, ctx_err = Context.get_from_path(bufnr)
    if ctx_err then
      return reject(ctx_err)
    end

    local collector = ctx.collector
    collector:discard()

    local start_err = collector:start(nil, resolve, reject)
    if start_err ~= nil then
      return reject(start_err)
    end
  end):catch(function(e)
    require("thetto.vendor.misclib.message").warn(e)
  end)
end

function M.resume(source_name)
  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close(true)
  end

  local ctx, ctx_err = Context.resume(source_name)
  if ctx_err ~= nil then
    return Promise.reject(ctx_err)
  end

  return ctx.ui:resume()
end

function M.execute(action_name, raw_args)
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err then
    return Promise.reject(ctx_err)
  end
  return _execute_action(ctx, action_name, raw_args)
end

function M.get()
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err then
    require("thetto.vendor.misclib.message").error(ctx_err)
  end
  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  return ctx.ui:selected_items(nil, range)
end

function M.resume_execute(raw_args)
  local args = require("thetto.core.argument").ResumeExecuteArgs.new(raw_args)
  local ctx, ctx_err = Context.resume(args.source_name)
  if ctx_err then
    return Promise.reject(ctx_err)
  end
  ctx.ui:update_offset(args.opts.offset)

  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  local items = ctx.ui:selected_items(args.action_name, range)
  return ctx.executor:actions(items, ctx, args.action_name, {}, args.action_opts)
end

function M.setup(setting)
  require("thetto.core.option").set_default(setting)
end

function M.setup_store(name, opts)
  local store, err = require("thetto.core.store").new(name, opts)
  if err then
    require("thetto.vendor.misclib.message").error(err)
  end
  store:start()
end

function M.register_source(name, handler)
  require("thetto.core.items.source").register(name, handler)
end

return M
