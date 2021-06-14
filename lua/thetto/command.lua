local Collector = require("thetto/core/collector").Collector
local Executor = require("thetto/core/executor").Executor
local Options = require("thetto/core/option").Options
local UI = require("thetto/view/ui").UI
local messagelib = require("thetto/lib/message")
local repository = require("thetto/core/repository")
local modulelib = require("thetto/lib/module")
local modelib = require("thetto/lib/mode")

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
  args = args or {}
  local source_opts = args.source_opts or {}
  local action_opts = args.action_opts or {}

  local opts, opts_err = Options.new(args.opts or {})
  if opts_err ~= nil then
    return nil, opts_err
  end

  if source_name == nil then
    return nil, "no source"
  end

  local old_ctx = repository.get(source_name)
  if old_ctx.ui ~= nil then
    old_ctx.ui:close()
  end

  local collector, err = Collector.new(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local executor = Executor.new(source_name, action_opts, opts.action)
  local ui = UI.new(collector)

  local ctx = {collector = collector, ui = ui, executor = executor}
  repository.set(source_name, ctx)

  local start_err = collector:start()
  if start_err ~= nil then
    return nil, start_err
  end

  ui:open(executor:auto(ctx, opts.auto, action_opts))

  err = collector:update()
  if err ~= nil then
    return nil, err
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
  local old_ctx = repository.get(source_name)
  if old_ctx.ui ~= nil then
    old_ctx.ui:close()
  end

  local ctx, err = repository.resume(source_name)
  if err ~= nil then
    return nil, err
  end
  err = ctx.ui:resume()
  if err ~= nil then
    return nil, err
  end
  return ctx.collector, nil
end

function Command.execute(action_name, args)
  args = args or {}
  local action_opts = args.action_opts or {}

  local ctx, ctx_err = repository.get_from_path()
  if ctx_err ~= nil then
    return nil, "not found state: " .. ctx_err
  end

  if action_name == nil then
    action_name = "default"
  end

  local range = modelib.visual_range()
  local item_groups = ctx.ui:current_item_groups(action_name, range)
  local executor = ctx.executor
  for _, item_group in ipairs(item_groups) do
    local kind_name, items = unpack(item_group)
    local err = executor:add(action_name, kind_name, items, action_opts)
    if err ~= nil then
      return nil, err
    end
  end

  return executor:batch(ctx)
end

function Command.resume_execute(args)
  args = args or {}
  local action_opts = args.action_opts or {}
  local opts = args.opts or {}

  local ctx = repository.resume()
  ctx.ui:update_offset(opts.offset)

  local action_name = "default"
  local range = modelib.visual_range()
  local item_groups = ctx.ui:current_item_groups(action_name, range)
  local executor = ctx.executor
  for _, item_group in ipairs(item_groups) do
    local kind_name, items = unpack(item_group)
    local err = executor:add(action_name, kind_name, items, action_opts)
    if err ~= nil then
      return nil, err
    end
  end

  return executor:batch(ctx)
end

function Command.setup(name)
  local setup = modulelib.find_setup(name)
  return setup.start()
end

return M
