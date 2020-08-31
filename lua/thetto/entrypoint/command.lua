local notifiers = require("thetto/lib/notifier")
local collector_core = require("thetto/core/collector")
local wraplib = require("thetto/lib/wrap")
local messagelib = require("thetto/lib/message")
local listlib = require("thetto/lib/list")
local custom = require("thetto/custom")
local uis = require("thetto/view/ui")
local repository = require("thetto/core/repository")
local executors = require("thetto/core/executor")
local cmdparse = require("thetto/lib/cmdparse")

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
  action = nil,
  display_limit = 100,
  debounce_ms = 50,
  filters = {},
  sorters = {},
  allow_empty = false,
  preview = false,
}

M.start_by_excmd = function(raw_args)
  local source_name, opts, ex_opts, parse_err = cmdparse.args(raw_args, vim.tbl_extend("force", start_default_opts, custom.opts))
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  if source_name == nil and not opts.resume then
    return nil, messagelib.error("no source")
  end

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

M.start = function(source_name, args)
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
  if opts.resume then
    local ctx, err = repository.resume(source_name)
    if err ~= nil then
      return nil, err
    end
    ctx.ui:resume()
    return ctx.collector, nil
  end

  local notifier = notifiers.new()
  local collector, err = collector_core.create(notifier, source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end
  local executor = executors.create(notifier, source_name, action_opts, opts.action)
  local ui = uis.new(collector, notifier)

  repository.set(source_name, {collector = collector, ui = ui, executor = executor})

  err = collector:start()
  if err ~= nil then
    return nil, err
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

  local range = {first = raw_range[1], last = raw_range[2], given = has_range ~= 0}
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

  local selected_items = ctx.ui:selected_items(action_name, range)
  local item_groups = listlib.group_by(selected_items, function(item)
    return item.kind_name or ctx.collector.source.kind_name
  end)
  if #item_groups == 0 then
    table.insert(item_groups, {"base", {}})
  end

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

vim.api.nvim_command("doautocmd User ThettoSourceLoad")

return M
