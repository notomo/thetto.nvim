local ReturnValue = require("thetto.vendor.misclib.error_handler").for_return_value()
local ShowError = require("thetto.vendor.misclib.error_handler").for_show_error()

local Context = require("thetto.core.context")

local _execute_action = function(ctx, action_name, raw_args)
  local args = require("thetto.core.argument").ExecuteArgs.new(
    action_name or ctx.collector.source.default_action,
    raw_args
  )
  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  local items = ctx.ui:selected_items(args.action_name, range)
  return ctx.executor:actions(items, ctx, args.action_name, args.fallback_actions, args.action_opts)
end

function ReturnValue.start(source_name, raw_args)
  vim.validate({ source_name = { source_name, "string" } })

  local source_config
  source_name, source_config = require("thetto.core.option").resolve_alias(source_name)

  local args = require("thetto.core.argument").StartArgs.new(raw_args)
  local opts, source_opts, opts_err = require("thetto.core.option").Option.new(
    args.opts,
    args.source_opts,
    source_config
  )
  if opts_err ~= nil then
    require("thetto.vendor.misclib.message").warn(opts_err)
    return require("thetto.vendor.promise").resolve()
  end

  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close()
  end

  local collector, err = require("thetto.core.collector").new(source_name, source_opts, opts)
  if err ~= nil then
    require("thetto.vendor.misclib.message").warn(err)
    return require("thetto.vendor.promise").resolve()
  end

  local execute_opts = require("thetto.core.option").ExecuteOption.new(source_name, collector.source.actions)
  local executor = require("thetto.core.executor").new(
    collector.source.kind_name,
    args.action_opts,
    opts.action,
    execute_opts
  )
  local ui = require("thetto.view.ui").new(collector, opts.insert)
  local ctx = Context.new(source_name, collector, ui, executor, opts.can_resume)

  local promise = require("thetto.vendor.promise").new(function(resolve, reject)
    local start_err = collector:start(opts.pattern, resolve, reject)
    if start_err ~= nil then
      return reject(start_err)
    end

    ui:open(opts.immediately, executor:auto(ctx, opts.auto))
    if opts.immediately then
      ui:close(nil, opts.immediately)
    end

    local update_err = collector:update()
    if update_err ~= nil then
      return reject(update_err)
    end
  end):next(function()
    ui:scroll(opts.offset, opts.search_offset)
  end)

  if not opts.immediately then
    return promise:catch(function(e)
      require("thetto.vendor.misclib.message").warn(e)
    end)
  end

  return promise
    :next(function()
      local _, exec_err = _execute_action(ctx, opts.action, { action_opts = args.action_opts })
      if exec_err ~= nil then
        return require("thetto.vendor.misclib.message").warn(exec_err)
      end
    end)
    :catch(function(e)
      require("thetto.vendor.misclib.message").warn(e)
    end)
end

function ReturnValue.reload(bufnr)
  local ctx, ctx_err = Context.get_from_path(bufnr)
  if ctx_err then
    return nil, ctx_err
  end

  local collector = ctx.collector

  local start_err = collector:start()
  if start_err ~= nil then
    return nil, start_err
  end

  local update_err = collector:update()
  if update_err ~= nil then
    return nil, update_err
  end

  return collector, nil
end

function ReturnValue.resume(source_name)
  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close(true)
  end

  local ctx, ctx_err = Context.resume(source_name)
  if ctx_err ~= nil then
    return nil, ctx_err
  end

  local err = ctx.ui:resume()
  if err ~= nil then
    return nil, err
  end
  return ctx.collector, nil
end

function ReturnValue.execute(action_name, raw_args)
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err ~= nil then
    return nil, ctx_err
  end
  return _execute_action(ctx, action_name, raw_args)
end

function ReturnValue.get()
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err ~= nil then
    return nil, ctx_err
  end
  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  return ctx.ui:selected_items(nil, range)
end

function ReturnValue.resume_execute(raw_args)
  local args = require("thetto.core.argument").ResumeExecuteArgs.new(raw_args)
  local ctx, ctx_err = Context.resume(args.source_name)
  if ctx_err ~= nil then
    return nil, ctx_err
  end
  ctx.ui:update_offset(args.opts.offset)

  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  local items = ctx.ui:selected_items(args.action_name, range)
  return ctx.executor:action(items, ctx, args.action_name, args.action_opts)
end

function ShowError.setup(setting)
  return require("thetto.core.option").set_default(setting)
end

function ShowError.setup_store(name, opts)
  local store, err = require("thetto.core.store").new(name, opts)
  if err ~= nil then
    return err
  end
  return store:start()
end

function ShowError.register_source(name, handler)
  return require("thetto.core.items.source").register(name, handler)
end

return vim.tbl_extend("force", ReturnValue:methods(), ShowError:methods())
