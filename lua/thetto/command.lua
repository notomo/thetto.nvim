local ReturnValue = require("thetto.vendor.misclib.error_handler").for_return_value()
local ShowError = require("thetto.vendor.misclib.error_handler").for_show_error()

local Context = require("thetto.core.context")

function ReturnValue.start(source_name, raw_args)
  vim.validate({ source_name = { source_name, "string" } })

  local args = require("thetto.core.argument").StartArgs.new(raw_args)
  local opts, source_opts, opts_err = require("thetto.core.option").Option.new(args.opts, args.source_opts, source_name)
  if opts_err ~= nil then
    return nil, opts_err
  end
  local execute_opts = require("thetto.core.option").ExecuteOption.new(source_name)

  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close()
  end

  local collector, err = require("thetto.core.collector").new(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local executor = require("thetto.core.executor").new(
    collector.source.kind_name,
    args.action_opts,
    opts.action,
    execute_opts
  )
  local ui = require("thetto.view.ui").new(collector, opts.insert, opts.display_limit)
  local ctx = Context.new(source_name, collector, ui, executor, opts.can_resume)

  local start_err = collector:start(opts.pattern)
  if start_err ~= nil then
    return nil, start_err
  end

  ui:open(executor:auto(ctx, opts.auto))

  local update_err = collector:update()
  if update_err ~= nil then
    return nil, update_err
  end
  ui:scroll(opts.offset)

  if opts.immediately then
    local _, exec_err = ReturnValue.execute(opts.action, { action_opts = args.action_opts })
    if exec_err ~= nil then
      return nil, exec_err
    end
  end

  return collector, nil
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
    old_ctx.ui:close()
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
  local args = require("thetto.core.argument").ExecuteArgs.new(
    action_name or ctx.collector.source.default_action,
    raw_args
  )
  local range = require("thetto.vendor.misclib.visual_mode").row_range()
  local items = ctx.ui:selected_items(args.action_name, range)
  return ctx.executor:actions(items, ctx, args.action_name, args.fallback_actions, args.action_opts)
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
