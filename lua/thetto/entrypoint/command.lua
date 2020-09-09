local notifiers = require("thetto/lib/notifier")
local collector_core = require("thetto/core/collector")
local wraplib = require("thetto/lib/wrap")
local messagelib = require("thetto/lib/message")
local custom = require("thetto/custom")
local uis = require("thetto/view/ui")
local repository = require("thetto/core/repository")
local executors = require("thetto/core/executor")
local cmdparse = require("thetto/lib/cmdparse")
local modulelib = require("thetto/lib/module")

local M = {}

local start_default_opts = {
  insert = true,
  resume = false,
  ignorecase = false,
  smartcase = true,
  pattern = nil,
  pattern_type = nil,
  offset = 0,
  cwd = ".",
  target = nil,
  target_patterns = {},
  action = nil,
  display_limit = 100,
  debounce_ms = 50,
  filters = {},
  sorters = {},
  allow_empty = false,
  auto = nil,
}

M.start_by_excmd = function(has_range, raw_range, raw_args)
  local source_name, opts, ex_opts, parse_err = cmdparse.args(raw_args, vim.tbl_extend("force", start_default_opts, custom.opts))
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  local range = nil
  if has_range ~= 0 then
    range = {first = raw_range[1], last = raw_range[2]}
  end
  opts.range = range

  local source_opts = ex_opts.x or {}
  local action_opts = ex_opts.xx or {}
  local result, err = wraplib.traceback(function()
    return M._start(source_name, source_opts, action_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M.start = function(args)
  local source_name = args.source_name
  local source_opts = args.source_opts or {}
  local action_opts = args.action_opts or {}
  local opts = vim.tbl_extend("force", start_default_opts, custom.opts, args.opts or {})
  local result, err = wraplib.traceback(function()
    return M._start(source_name, source_opts, action_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M._start = function(source_name, source_opts, action_opts, opts)
  if source_name == nil and not opts.resume then
    return nil, "no source"
  end

  local old_ctx = repository.get(source_name)
  if old_ctx.ui ~= nil then
    old_ctx.ui:close()
  end

  if opts.resume then
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

  local notifier = notifiers.new()
  local collector, err = collector_core.create(notifier, source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local executor = executors.create(notifier, source_name, action_opts, opts.action)
  local ui = uis.new(collector, notifier)

  local ctx = {collector = collector, ui = ui, executor = executor}
  repository.set(source_name, ctx)

  err = collector:start()
  if err ~= nil then
    return nil, err
  end

  if opts.auto == nil then
    notifier:on("execute", function()
    end)
  else
    notifier:on("execute", function()
      local item_group = ui:current_item_groups()[1]
      local kind_name, items = unpack(item_group)
      local _, exec_err = executor:action(ctx, opts.auto, kind_name, items, action_opts)
      return exec_err
    end)
  end

  ui:open()

  err = collector:update()
  if err ~= nil then
    return nil, err
  end

  return collector, nil
end

M.execute = function(has_range, raw_range, raw_args)
  local action_name, opts, ex_opts, parse_err = cmdparse.args(raw_args, {resume = false, offset = 0})
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  if action_name == nil then
    action_name = "default"
  end

  local range = nil
  if has_range ~= 0 then
    range = {first = raw_range[1], last = raw_range[2]}
  end

  local action_opts = ex_opts.x or {}
  local result, err = wraplib.traceback(function()
    return M._execute(action_name, range, action_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M._execute = function(action_name, range, action_opts, opts)
  local ctx
  if opts.resume then
    ctx = repository.resume()
    ctx.ui:update_offset(opts.offset)
  else
    local err
    ctx, err = repository.get_from_path()
    if err ~= nil then
      return nil, "not found state: " .. err
    end
  end

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

M.setup = function(raw_args)
  local setup_name, _, _, parse_err = cmdparse.args(raw_args, {})
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  local setup = modulelib.find_setup(setup_name)
  local result, err = wraplib.traceback(function()
    return setup.start()
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

vim.api.nvim_command("doautocmd User ThettoSourceLoad")

return M
