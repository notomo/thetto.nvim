local kinds = require "thetto/kind"
local states = require "thetto/state"
local util = require "thetto/util"

local M = {}

M.limit = 100
M.debounce_ms = 50

local make_list_buffer = function(candidates, opts)
  local lines = {}
  local filtered = vim.tbl_values({unpack(candidates, 0, M.limit)})
  for _, candidate in pairs(filtered) do
    table.insert(lines, candidate.value)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local window_id =
    vim.api.nvim_open_win(
    bufnr,
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
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype", states.list_filetype)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  return {
    window = window_id,
    bufnr = bufnr,
    all = candidates,
    filtered = filtered
  }
end

local make_filter_buffer = function(opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local window_id =
    vim.api.nvim_open_win(
    bufnr,
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
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype", states.filter_filetype)

  return {
    window = window_id,
    bufnr = bufnr
  }
end

-- for testing
M._changed_after = function()
end

local on_changed = function(filter_bufnr)
  local state = states.get()
  local line = vim.api.nvim_buf_get_lines(filter_bufnr, 0, 1, true)[1]

  local texts = vim.split(line, "%s")
  local lines = {}
  local filtered = {}
  for _, candidate in pairs(state.list.all) do
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
      if not vim.api.nvim_buf_is_valid(state.list.bufnr) then
        return
      end
      vim.api.nvim_buf_set_option(state.list.bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(state.list.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(state.list.bufnr, "modifiable", false)
      vim.api.nvim_win_set_cursor(state.list.window, {1, 0})
      M._changed_after()
    end
  )
end

M.start = function(args)
  local source = util.find_source(args.source_name)
  if source == nil then
    return "not found source: " .. args.source_name
  end

  local opts = args
  opts.width = 80
  opts.height = 25
  opts.row = vim.o.lines / 2 - (opts.height / 2)
  opts.column = vim.o.columns / 2 - (opts.width / 2)

  local candidates = source.make()
  local filter_buffer = make_filter_buffer(opts)
  local list_buffer = make_list_buffer(candidates, opts)

  if opts.insert then
    vim.api.nvim_set_current_win(filter_buffer.window)
    vim.api.nvim_command("startinsert")
  else
    vim.api.nvim_set_current_win(list_buffer.window)
  end

  vim.api.nvim_buf_attach(filter_buffer.bufnr, false, {on_lines = util.debounce(M.debounce_ms, on_changed)})

  local on_list_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(
    list_buffer.bufnr,
    filter_buffer.window
  )
  vim.api.nvim_command(on_list_closed)

  local on_filter_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close_window(%s)"):format(
    filter_buffer.bufnr,
    list_buffer.window
  )
  vim.api.nvim_command(on_filter_closed)

  states.set(list_buffer, filter_buffer, source.kind_name)
end

M.execute = function(args)
  local state = states.get()
  if state == nil then
    return
  end

  local kind = kinds.find(state.kind_name, args.action)
  if kind == nil then
    return "not found kind: " .. state.kind_name
  end

  local opts = kind.options(args)

  local action = kind.find_action(args.action)
  if action == nil then
    return "not found action: " .. args.action
  end

  local candidate = state.select_from_list()
  local candidates = {}
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

return M
