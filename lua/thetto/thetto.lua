local kinds = require "thetto/kind"
local states = require "thetto/state"
local util = require "thetto/util"

local M = {}

M.limit = 100
M.debounce_ms = 50

local open_windows = function(buffers, opts)
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

  local on_list_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.list, input_window)
  vim.api.nvim_command(on_list_closed)

  local on_input_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.input, list_window)
  vim.api.nvim_command(on_input_closed)

  if opts.insert then
    vim.api.nvim_set_current_win(input_window)
    vim.api.nvim_command("startinsert")
  else
    vim.api.nvim_set_current_win(list_window)
  end

  return {list = list_window, input = input_window}
end

local on_changed = function(all_items, input_bufnr, iteradapter_names)
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

  state.update(M._head_items(items))

  local bufnr = state.buffers.list
  local window = state.windows.list
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local lines = M._head_lines(items)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    if vim.bo.filetype ~= states.list_filetype then
      vim.api.nvim_win_set_cursor(window, {1, 0})
    end
    M._changed_after()
  end)
end

local make_buffers = function(opts)
  local source_name = opts.source_name

  if opts.resume then
    local state = states.recent(source_name)
    if state == nil then
      return nil, "no source to resume"
    end
    return state.buffers
  end

  local source = util.find_source(source_name)
  if source == nil then
    return nil, "not found source: " .. source_name
  end

  local all_items = {}
  local job = nil
  local iteradapter_names = source.iteradapter_names or {"filter/substring"}
  local debounced_update = util.debounce(M.debounce_ms, function(bufnr)
    return on_changed(all_items, bufnr, iteradapter_names)
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

  local list = {
    set = function(items)
      all_items = items
      debounced_update(input_bufnr)
    end,
  }

  all_items, job = source.make(list, opts)
  local items = M._head_items(all_items)
  local lines = M._head_lines(items)
  local list_bufnr = util.create_buffer(("thetto://%s/%s"):format(source_name, states.list_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  return {
    list = list_bufnr,
    input = input_bufnr,
    filtered = items,
    kind_name = source.kind_name,
    opts = opts,
  }, job, nil
end

M.start = function(args)
  local opts = args

  local buffers, job, err = make_buffers(opts)
  if err ~= nil then
    return nil, err
  end

  local windows = open_windows(buffers, opts)

  states.set(buffers, windows)
  if job ~= nil then
    job:start()
  end

  return job, nil
end

M.execute = function(args)
  local state, err = states.get(0)
  if err ~= nil then
    return err
  end

  local kind = kinds.find(state.buffers.kind_name, args.action)
  if kind == nil then
    return "not found kind: " .. state.buffers.kind_name
  end

  local opts = kind.options(args)

  local action = kind.find_action(args.action)
  if action == nil then
    return "not found action: " .. args.action
  end

  local items = {}
  local item = state.select_from_list()
  if item ~= nil then
    table.insert(items, item)
  end

  if opts.quit then
    state.close()
  end

  return action(items, state.fixed())
end

M.close_window = function(id)
  util.close_window(id)
end

M._head_items = function(items)
  local filtered = {}
  for i = 1, M.limit, 1 do
    filtered[i] = items[i]
  end
  return filtered
end

M._head_lines = function(items)
  local filtered = M._head_items(items)
  local lines = {}
  for _, item in pairs(filtered) do
    table.insert(lines, item.value)
  end
  return lines
end

-- for testing
M._changed_after = function()
end

return M
