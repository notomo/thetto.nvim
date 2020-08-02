local kinds = require "thetto/core/base_kind"
local sources = require "thetto/core/base_source"
local states = require "thetto/core/state"
local listlib = require "thetto/lib/list"
local bufferlib = require "thetto/lib/buffer"
local modulelib = require "thetto/lib/module"
local messagelib = require "thetto/lib/message"
local wraplib = require "thetto/lib/wrap"
local inputs = require "thetto/input"
local ui_windows = require "thetto/view/ui"

local M = {}

local on_changed = function(all_items, input_bufnr, source)
  local state, err = states.get(nil, input_bufnr)
  if err ~= nil then
    return messagelib.error(err)
  end

  local input_line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, true)[1]
  local opts = vim.deepcopy(state.buffers.opts)
  if not opts.ignorecase and opts.smartcase and input_line:find("[A-Z]") then
    opts.ignorecase = false
  else
    opts.ignorecase = true
  end

  for _, item in ipairs(state.buffers.filtered) do
    if item.selected ~= nil then
      all_items[item.index].selected = item.selected
    end
  end
  local items = M._modify_items(source, all_items, input_line, opts)

  state:update(items)

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(state.buffers.list) then
      return
    end
    ui_windows.render(source, items, #all_items, state.buffers, state.windows, input_line, opts)
    M._changed_after()
  end)
end

local make_buffers = function(source_name, source_opts, resumed_state, opts)
  if resumed_state ~= nil then
    return resumed_state.buffers
  end

  local source, err = sources.create(source_name, source_opts, opts)
  if err ~= nil then
    return nil, nil, nil, nil, nil, err
  end

  local all_items = {}
  local job = nil
  local input_bufnr = nil
  local update_list = wraplib.debounce(opts.debounce_ms, function()
    return on_changed(all_items, input_bufnr, source)
  end)

  input_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source_name, states.input_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.input_filetype)
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = update_list,
      on_detach = function()
        if job ~= nil then
          job:stop()
        end
      end,
    })
  end)

  source.append = function(items)
    local len = #all_items
    for i, item in ipairs(items) do
      item.index = len + i
    end
    vim.list_extend(all_items, items)
    update_list()
  end

  all_items, job = source:collect(opts)
  for i, item in ipairs(all_items) do
    item.index = i
  end

  local sign_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source_name, states.sign_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.sign_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, opts.display_limit))
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  local list_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source_name, states.list_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
  end)

  local info_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source_name, states.info_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.info_filetype)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  local items = M._modify_items(source, all_items, "", opts)
  return {
    list = list_bufnr,
    input = input_bufnr,
    info = info_bufnr,
    sign = sign_bufnr,
    filtered = items,
    selected = {},
    kind_name = source.kind_name,
    source_name = source_name,
    opts = opts,
  }, source, job, items, #all_items, nil
end

M.start = function(source_name, source_opts, action_opts, args)
  local opts = args

  opts.cwd = vim.fn.expand(opts.cwd)
  if opts.cwd == "." then
    opts.cwd = vim.fn.fnamemodify(".", ":p")
  end
  if opts.cwd ~= "/" and vim.endswith(opts.cwd, "/") then
    opts.cwd = opts.cwd:sub(1, #opts.cwd - 1)
  end

  if opts.target ~= nil then
    local target = modulelib.find_target(opts.target)
    if target == nil then
      return nil, "not found target: " .. opts.target
    end
    opts.cwd = target.cwd()
  end

  if opts.pattern_type ~= nil then
    local pattern = inputs.get(opts.pattern_type)
    if pattern == nil then
      return nil, "not found pattern type: " .. opts.pattern_type
    end
    opts.pattern = pattern
  end

  local resumed_state = nil
  if opts.resume then
    resumed_state = states.recent(source_name)
    if resumed_state == nil then
      return nil, "no source to resume"
    end
  end

  local buffers, source, job, items, all_items_count, err = make_buffers(source_name, source_opts, resumed_state, opts)
  if err ~= nil then
    return nil, err
  end
  buffers.action_opts = action_opts

  local windows = ui_windows.open(buffers, resumed_state, opts, function()
    if job ~= nil then
      job:stop()
    end
  end)

  states.set(buffers, windows)
  if job ~= nil then
    job:start()
  end

  if source ~= nil then
    ui_windows.render(source, items, all_items_count, buffers, windows, "", opts)
  end

  return job, nil
end

M.execute = function(action_name, action_opts, args)
  local state, err
  if args.resume then
    state = states.recent(nil)
    if state == nil then
      err = "no source to resume"
    end
  else
    state, err = states.get(0)
  end
  if err ~= nil then
    return nil, err
  end

  local selected_items = state:selected_items(action_name, args.offset)
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

M._modify_items = function(source, all_items, input_line, opts)
  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in ipairs(all_items) do
    table.insert(items, item)
  end

  if input_line ~= "" then
    for _, filter in ipairs(source.iteradapter.filters) do
      items = filter.apply(items, input_line, opts)
    end
  end
  for _, sorter in ipairs(source.iteradapter.sorters) do
    items = sorter.apply(items, input_line, opts)
  end

  local filtered = {}
  for i = 1, opts.display_limit, 1 do
    filtered[i] = items[i]
  end
  return filtered
end

-- for testing
M._changed_after = function()
end

return M
