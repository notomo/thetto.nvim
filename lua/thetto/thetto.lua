local kinds = require "thetto/kind"
local sources = require "thetto/source"
local states = require "thetto/state"
local highlights = require("thetto/highlight")
local util = require "thetto/util"
local inputs = require "thetto/input"

local M = {}

local open_windows = function(buffers, resumed_state, opts)
  local ids = vim.api.nvim_tabpage_list_wins(0)
  for _, id in ipairs(ids) do
    local bufnr = vim.fn.winbufnr(id)
    if bufnr == -1 then
      goto continue
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path:match(states.path_pattern) then
      M.close_window(id)
    end
    ::continue::
  end

  local row = vim.o.lines / 2 - (opts.height / 2)
  local column = vim.o.columns / 2 - (opts.width / 2)

  local list_window = vim.api.nvim_open_win(buffers.list, true, {
    width = opts.width,
    height = opts.height,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
  })

  local input_window = vim.api.nvim_open_win(buffers.input, true, {
    width = opts.width,
    height = 1,
    relative = "editor",
    row = row + opts.height,
    col = column,
    external = false,
    style = "minimal",
  })

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
      vim.api.nvim_win_set_cursor(list_window, cursor)
    end
    if resumed_state.windows.input_cursor then
      vim.api.nvim_win_set_cursor(input_window, resumed_state.windows.input_cursor)
    end
  end

  local on_list_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.list, input_window)
  vim.api.nvim_command(on_list_closed)

  local on_input_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.input, list_window)
  vim.api.nvim_command(on_input_closed)

  local insert = opts.insert
  if resumed_state ~= nil and resumed_state.windows.active == "list" then
    insert = false
  end
  if insert then
    vim.api.nvim_set_current_win(input_window)
    vim.api.nvim_command("startinsert")
  else
    vim.api.nvim_set_current_win(list_window)
  end

  return {list = list_window, input = input_window}
end

local on_changed = function(all_items, input_bufnr, iteradapter_names, source)
  local state, err = states.get(0)
  if err ~= nil then
    return util.print_err(err)
  end

  local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, true)[1]
  local opts = vim.deepcopy(state.buffers.opts)
  if not opts.ignorecase and opts.smartcase and line:find("[A-Z]") then
    opts.ignorecase = false
  else
    opts.ignorecase = true
  end

  for _, item in ipairs(state.buffers.filtered) do
    if item.selected ~= nil then
      all_items[item.index].selected = item.selected
    end
  end

  -- NOTE: avoid `too many results to unpack`
  local items = {}
  for _, item in ipairs(all_items) do
    table.insert(items, item)
  end

  for _, name in ipairs(iteradapter_names) do
    local iteradapter = util.find_iteradapter(name)
    if iteradapter == nil then
      return util.print_err("not found iteradapter: " .. name)
    end
    items = iteradapter.apply(items, line, opts)
  end

  items = M._head_items(items, opts.display_limit)
  state:update(items)

  local bufnr = state.buffers.list
  local window = state.windows.list
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    local lines = M._head_lines(items, opts.display_limit)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    if vim.bo.filetype ~= states.list_filetype then
      vim.api.nvim_win_set_cursor(window, {1, 0})
    end

    if source.highlight ~= nil then
      source:highlight(bufnr, items)
    end
    highlights.update_selections(bufnr, items)

    M._changed_after()
  end)
end

local make_buffers = function(source_name, source_opts, resumed_state, opts)
  if resumed_state ~= nil then
    return resumed_state.buffers, nil, nil
  end

  local source, err = sources.create(source_name, source_opts)
  if err ~= nil then
    return nil, nil, err
  end

  local all_items = {}
  local job = nil
  local iteradapter_names = source.iteradapter_names or {"filter/substring"}
  local debounced_update = util.debounce(opts.debounce_ms, function(bufnr)
    return on_changed(all_items, bufnr, iteradapter_names, source)
  end)

  local input_bufnr = util.create_buffer(("thetto://%s/%s"):format(source_name, states.input_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.input_filetype)
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = debounced_update,
      on_detach = function()
        if job == nil then
          return
        end
        job:stop()
      end,
    })
  end)

  source.append = function(items)
    local len = #all_items
    for i, item in ipairs(items) do
      item.index = len + i
    end
    vim.list_extend(all_items, items)
    debounced_update(input_bufnr)
  end

  all_items, job = source:collect(opts)
  for i, item in ipairs(all_items) do
    item.index = i
  end

  local items = M._head_items(all_items, opts.display_limit)
  local lines = M._head_lines(items, opts.display_limit)
  local list_bufnr = util.create_buffer(("thetto://%s/%s"):format(source_name, states.list_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    if source.highlight ~= nil then
      source:highlight(bufnr, items)
    end
  end)

  return {
    list = list_bufnr,
    input = input_bufnr,
    filtered = items,
    selected = {},
    kind_name = source.kind_name,
    source_name = source_name,
    opts = opts,
  }, job, nil
end

M.start = function(source_name, source_opts, args)
  local opts = args

  opts.cwd = vim.fn.expand(opts.cwd)

  if opts.target ~= nil then
    local target = util.find_target(opts.target)
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

  local buffers, job, err = make_buffers(source_name, source_opts, resumed_state, opts)
  if err ~= nil then
    return nil, err
  end

  local windows = open_windows(buffers, resumed_state, opts)

  states.set(buffers, windows)
  if job ~= nil then
    job:start()
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
  local item_groups = util.group_by(selected_items, function(item)
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
    local kind, _opts, kind_err = kinds.create(kind_name, action_name, args)
    if kind_err ~= nil then
      return nil, kind_err
    end
    opts = _opts

    local action, _action_opts, action_err = kinds.find_action(kind, action_opts, action_name, state.buffers.opts.action, state.buffers.source_name)
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

M.close_window = function(id)
  util.close_window(id)
end

M._head_items = function(items, limit)
  local filtered = {}
  for i = 1, limit, 1 do
    filtered[i] = items[i]
  end
  return filtered
end

M._head_lines = function(items, limit)
  local filtered = M._head_items(items, limit)
  local lines = {}
  for _, item in pairs(filtered) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

-- for testing
M._changed_after = function()
end

return M
