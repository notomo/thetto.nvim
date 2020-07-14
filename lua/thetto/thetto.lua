local kinds = require "thetto/kind"
local states = require "thetto/state"
local util = require "thetto/util"

local M = {}

M.limit = 100
M.debounce_ms = 50

local open_windows = function(buffers, opts)
  local row = vim.o.lines / 2 - (opts.height / 2)
  local column = vim.o.columns / 2 - (opts.width / 2)

  local list_window =
    vim.api.nvim_open_win(
    buffers.list,
    true,
    {
      width = opts.width,
      height = opts.height,
      relative = "editor",
      row = row,
      col = column,
      external = false,
      style = "minimal"
    }
  )

  local input_window =
    vim.api.nvim_open_win(
    buffers.input,
    true,
    {
      width = opts.width,
      height = 1,
      relative = "editor",
      row = row + opts.height,
      col = column,
      external = false,
      style = "minimal"
    }
  )

  local on_list_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.list, input_window)
  vim.api.nvim_command(on_list_closed)

  local on_input_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(buffers.input, list_window)
  vim.api.nvim_command(on_input_closed)

  if opts.insert then
    vim.api.nvim_set_current_win(input_window)
    vim.api.nvim_command("startinsert")
  else
    vim.api.nvim_set_current_win(list_window)
  end

  return {list = list_window, input = input_window}
end

local on_changed = function(input_bufnr)
  local state, err = states.get(0)
  if err ~= nil then
    return util.print_err(err)
  end

  local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, true)[1]
  local opts = vim.deepcopy(state.buffers.opts)
  if not opts.ignorecase and opts.smartcase and line:find("[A-Z]") then
    opts.ignorecase = false
  end

  local items = {unpack(state.buffers.all)}
  for _, name in ipairs(state.buffers.iteradapter_names) do
    local iteradapter = util.find_iteradapter(name)
    if iteradapter == nil then
      return util.print_err("not found iteradapter: " .. name)
    end
    items = iteradapter.apply(items, line, opts)
  end

  state.update(items)

  local _, lines = M._head(items)
  local bufnr = state.buffers.list
  local window = state.windows.list
  vim.schedule(
    function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
      vim.api.nvim_win_set_cursor(window, {1, 0})
      M._changed_after()
    end
  )
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

  local all_items = source.make()
  local items, lines = M._head(all_items)
  local list_bufnr =
    util.create_buffer(
    ("thetto://%s/%s"):format(source_name, states.list_filetype),
    function(bufnr)
      vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    end
  )

  local input_bufnr =
    util.create_buffer(
    ("thetto://%s/%s"):format(source_name, states.input_filetype),
    function(bufnr)
      vim.api.nvim_buf_set_option(bufnr, "filetype", states.input_filetype)
      vim.api.nvim_buf_attach(bufnr, false, {on_lines = util.debounce(M.debounce_ms, on_changed)})
    end
  )

  return {
    list = list_bufnr,
    input = input_bufnr,
    all = all_items,
    filtered = items,
    kind_name = source.kind_name,
    iteradapter_names = source.iteradapter_names or {"filter/substring"},
    opts = opts
  }, nil
end

M.start = function(args)
  local opts = args

  local buffers, err = make_buffers(opts)
  if err ~= nil then
    return err
  end

  local windows = open_windows(buffers, opts)

  states.set(buffers, windows)
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

M._head = function(items)
  local lines = {}
  local filtered = vim.tbl_values({unpack(items, 0, M.limit)})
  for _, item in pairs(items) do
    table.insert(lines, item.value)
  end
  return filtered, lines
end

-- for testing
M._changed_after = function()
end

return M
