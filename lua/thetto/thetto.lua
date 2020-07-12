local kinds = require "thetto/kind"
local states = require "thetto/state"
local util = require "thetto/util"

local M = {}

M.limit = 100
M.debounce_ms = 50

local open_view = function(buffers, opts)
  local list_window =
    vim.api.nvim_open_win(
    buffers.list,
    true,
    {
      width = opts.width,
      height = opts.height,
      relative = "editor",
      row = opts.row,
      col = opts.column,
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
      row = opts.row + opts.height,
      col = opts.column,
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
    return err
  end
  local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, true)[1]

  local texts = vim.split(line, "%s")
  local lines = {}
  local filtered = {}
  for _, candidate in pairs(state.buffers.all) do
    local ok = true
    for _, text in ipairs(texts) do
      if not (candidate.value):find(text) then
        ok = false
        break
      end
    end

    if ok then
      table.insert(filtered, candidate)
    end
  end
  for _, c in pairs({unpack(filtered, 0, M.limit)}) do
    table.insert(lines, c.value)
  end

  state.update(filtered)

  vim.schedule(
    function()
      if not vim.api.nvim_buf_is_valid(state.buffers.list) then
        return
      end
      vim.api.nvim_buf_set_option(state.buffers.list, "modifiable", true)
      vim.api.nvim_buf_set_lines(state.buffers.list, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(state.buffers.list, "modifiable", false)
      vim.api.nvim_win_set_cursor(state.windows.list, {1, 0})
      M._changed_after()
    end
  )
end

local make_buffers = function(opts)
  if opts.resume then
    local state = states.recent(opts.source_name)
    if state == nil then
      return nil, "no source to resume"
    end
    return state.buffers
  end

  local source_name = opts.source_name
  local source = util.find_source(source_name)
  if source == nil then
    return nil, "not found source: " .. source_name
  end

  local candidates = source.make()
  local lines = {}
  local filtered = vim.tbl_values({unpack(candidates, 0, M.limit)})
  for _, candidate in pairs(filtered) do
    table.insert(lines, candidate.value)
  end

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

  return {list = list_bufnr, input = input_bufnr, all = candidates, filtered = filtered, kind_name = source.kind_name}, nil
end

M.start = function(args)
  local opts = args
  opts.width = 80
  opts.height = 25
  opts.row = vim.o.lines / 2 - (opts.height / 2)
  opts.column = vim.o.columns / 2 - (opts.width / 2)

  local buffers, err = make_buffers(opts)
  if err ~= nil then
    return err
  end

  local windows = open_view(buffers, opts)

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

  local candidates = {}
  local candidate = state.select_from_list()
  if candidate ~= nil then
    table.insert(candidates, candidate)
  end

  if opts.quit then
    state.close()
  end

  return action(candidates, state.fixed())
end

M.close_window = function(id)
  util.close_window(id)
end

-- for testing
M._changed_after = function()
end

return M
