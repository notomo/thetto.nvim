local kinds = require "thetto/core/kind"
local collector_core = require "thetto/core/collector"
local states = require "thetto/core/state"
local listlib = require "thetto/lib/list"
local bufferlib = require "thetto/lib/buffer"
local messagelib = require "thetto/lib/message"
local wraplib = require "thetto/lib/wrap"
local ui_windows = require "thetto/view/ui"

local M = {}

local on_changed = function(input_bufnr, collector)
  local state, err = states.get(nil, input_bufnr)
  if err ~= nil then
    if err == states.err_finished then
      return
    end
    return messagelib.error(err)
  end

  local input_lines = vim.api.nvim_buf_get_lines(input_bufnr, 0, -1, true)
  err = collector:update(input_lines, state.buffers.filters, state.buffers.sorters)
  if err ~= nil then
    return messagelib.error(err)
  end

  state:update(collector.items)

  vim.schedule(function()
    ui_windows.render(collector, state.buffers, state.windows, input_lines)
    M._changed_after()
  end)
end

local make_buffers = function(collector)
  local source = collector.source
  local opts = collector.opts

  local input_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, states.input_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.input_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, #source.filters))
  end)

  local update_list = wraplib.debounce(opts.debounce_ms, function()
    return on_changed(input_bufnr, collector)
  end)
  vim.api.nvim_buf_attach(input_bufnr, false, {
    on_lines = update_list,
    on_detach = function()
      collector:stop()
    end,
  })
  local err = collector:start(update_list)
  if err ~= nil then
    return nil, err
  end

  local sign_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, states.sign_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.sign_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, opts.display_limit))
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  local list_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, states.list_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
  end)

  local info_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, states.info_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.info_filetype)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  local filter_info_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, states.filter_info_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.filter_info_filetype)
  end)

  err = collector:update({}, source.filters, source.sorters)
  if err ~= nil then
    return nil, err
  end

  return {
    list = list_bufnr,
    input = input_bufnr,
    info = info_bufnr,
    filter_info = filter_info_bufnr,
    sign = sign_bufnr,
    filtered = collector.items,
    selected = {},
    kind_name = source.kind_name,
    source_name = source.name,
    filters = source.filters,
    sorters = source.sorters,
    opts = opts,
  }, nil
end

M.start = function(source_name, source_opts, action_opts, opts)
  local resumed_state
  if opts.resume then
    local state, err = states.resume(source_name)
    if err ~= nil then
      return nil, err
    end
    resumed_state = state
    source_name = resumed_state.buffers.source_name
  end

  local collector, err = collector_core.create(source_name, source_opts, opts)
  if err ~= nil then
    return nil, err
  end

  local buffers
  if resumed_state ~= nil then
    buffers = resumed_state.buffers
  else
    buffers, err = make_buffers(collector)
    if err ~= nil then
      return nil, err
    end
  end
  buffers.action_opts = action_opts

  local windows = ui_windows.open(buffers, collector.opts, function()
    collector:stop()
  end)
  M._set_mode(buffers, windows, resumed_state, collector.opts)

  states.set(buffers, windows)
  collector:start_job()

  if resumed_state == nil then
    local input_lines = {}
    ui_windows.render(collector, buffers, windows, input_lines)
  end

  return collector.job, nil
end

M.execute = function(action_name, range, action_opts, args)
  local state, err
  if args.resume then
    state, err = states.resume(nil)
  else
    state, err = states.get(0)
  end
  if err ~= nil then
    return nil, err
  end

  local selected_items = state:selected_items(action_name, range, args.offset)
  local item_groups = listlib.group_by(selected_items, function(item)
    return item.kind_name or state.buffers.kind_name
  end)

  local actions = {}
  local opts
  local i = 1
  repeat
    local kind_name, items
    if #item_groups == 0 then
      kind_name = state.buffers.kind_name
      items = {}
    else
      kind_name, items = unpack(item_groups[i])
    end
    local kind, _opts, kind_err = kinds.create(state.buffers.source_name, kind_name, action_name, args)
    if kind_err ~= nil then
      return nil, kind_err
    end
    opts = _opts

    local action, _action_opts, action_err = kinds.find_action(kind, vim.tbl_extend("force", state.buffers.action_opts, action_opts), action_name, state.buffers.opts.action, state.buffers.source_name)
    if action_err ~= nil then
      return nil, action_err
    end
    kind.action_opts = _action_opts

    table.insert(actions, function(_state)
      return action(kind, items, _state)
    end)

    i = i + 1
  until i > #item_groups

  if opts.quit then
    state:close(args.resume, args.offset)
  end

  local result, action_err
  for _, action in ipairs(actions) do
    result, action_err = action(state)
  end
  return result, action_err
end

M._set_mode = function(buffers, windows, resumed_state, opts)
  if resumed_state ~= nil then
    if resumed_state.windows.list_cursor then
      local cursor = resumed_state.windows.list_cursor
      cursor[1] = cursor[1] + opts.offset
      local line_count = vim.api.nvim_buf_line_count(buffers.list)
      if line_count < cursor[1] then
        cursor[1] = line_count
      elseif cursor[1] < 1 then
        cursor[1] = 1
      end
      vim.api.nvim_win_set_cursor(windows.list, cursor)
    end
    if resumed_state.windows.input_cursor then
      vim.api.nvim_win_set_cursor(windows.input, resumed_state.windows.input_cursor)
    end
  end

  local insert = opts.insert
  if resumed_state ~= nil and resumed_state.windows.active == "list" then
    insert = false
  end
  if insert then
    vim.api.nvim_set_current_win(windows.input)
    if resumed_state ~= nil and resumed_state.windows.mode == "n" then
      vim.api.nvim_command("stopinsert")
    else
      vim.api.nvim_command("startinsert")
    end
  else
    vim.api.nvim_set_current_win(windows.list)
  end
end

-- for testing
M._changed_after = function()
end

return M
