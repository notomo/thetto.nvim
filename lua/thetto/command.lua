local Collector = require("thetto.core.collector").Collector
local Executor = require("thetto.core.executor").Executor
local Options = require("thetto.core.option").Options
local Context = require("thetto.core.context").Context
local Store = require("thetto.core.store").Store
local UI = require("thetto.view.ui").UI
local custom = require("thetto.core.custom")
local messagelib = require("thetto.lib.message")
local modelib = require("thetto.lib.mode")

local M = {}

local Command = {}
Command.__index = Command
M.Command = Command

function Command.new(name, ...)
  local args = {...}
  local f = function()
    return Command[name](unpack(args))
  end

  local ok, result, msg = xpcall(f, debug.traceback)
  if not ok then
    return messagelib.error(result)
  elseif msg then
    return messagelib.warn(msg)
  end
  return result
end

function Command.start(source_name, args)
  vim.validate({source_name = {source_name, "string"}, args = {args, "table", true}})

  args = args or {}
  local source_opts = args.source_opts or {}
  local action_opts = args.action_opts or {}

  local opts, opts_err = Options.new(args.opts or {}, source_name)
  if opts_err ~= nil then
    return nil, opts_err
  end

  local old_ctx = Context.get(source_name)
  if old_ctx then
    old_ctx.ui:close()
  end

  local collector, err = Collector.new(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local executor = Executor.new(source_name, collector.source.kind_name, action_opts, opts.action)
  local ui = UI.new(collector)
  local ctx = Context.new(source_name, collector, ui, executor)

  local start_err = collector:start()
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
    local _, exec_err = Command.execute(opts.action, {action_opts = action_opts})
    if exec_err ~= nil then
      return exec_err
    end
  end

  return collector, nil
end

function Command.resume(source_name)
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

function Command.execute(action_name, args)
  args = args or {}
  local action_opts = args.action_opts or {}

  local ctx, ctx_err = Context.get_from_path()
  if ctx_err ~= nil then
    return nil, "not found state: " .. ctx_err
  end
  action_name = action_name or ctx.collector.source.default_action or "default"

  local range = modelib.visual_range()
  local items = ctx.ui:selected_items(action_name, range)
  return ctx.executor:action(items, ctx, action_name, action_opts)
end

function Command.resume_execute(args)
  args = args or {}
  local action_opts = args.action_opts or {}
  local opts = args.opts or {}

  local ctx, ctx_err = Context.resume(args.source_name)
  if ctx_err ~= nil then
    return nil, "not found state: " .. ctx_err
  end
  ctx.ui:update_offset(opts.offset or 0)

  local action_name = args.action_name or "default"
  local range = modelib.visual_range()
  local items = ctx.ui:selected_items(action_name, range)
  return ctx.executor:action(items, ctx, action_name, action_opts)
end

function Command.setup(config)
  vim.validate({config = {config, "table"}})
  custom.set(config)
end

function Command.setup_store(name, opts)
  local store, err = Store.new(name, opts)
  if err ~= nil then
    return nil, err
  end
  return nil, store:start()
end

function Command.add_to_store(name, ...)
  vim.validate({name = {name, "string"}})
  local store, err = Store.get(name)
  if err ~= nil then
    return nil, err
  end
  return nil, store:add(...)
end

function Command.save_to_store(name, ...)
  vim.validate({name = {name, "string"}})
  local store, err = Store.get(name)
  if err ~= nil then
    return nil, err
  end
  return nil, store:save(...)
end

return M
