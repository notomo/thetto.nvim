local base_kind = require "thetto/kind"

local M = {}

local state_key = "_thetto_state"
local filter_state_key = "_thetto_filter_state"
local filetype = "thetto"
local filter_filetype = "thetto-filter"

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
  vim.api.nvim_buf_set_option(bufnr, "filetype", filetype)
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
  vim.api.nvim_buf_set_option(bufnr, "filetype", filter_filetype)

  return {
    window = window_id,
    bufnr = bufnr
  }
end

-- for testing
M._changed_after = function()
end

local on_changed = function(filter_bufnr)
  local filter_state = vim.b[filter_state_key]
  local list_bufnr = filter_state.list.bufnr
  local state = vim.api.nvim_buf_get_var(list_bufnr, state_key)

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

  state.list.filtered = filtered
  vim.api.nvim_buf_set_var(list_bufnr, state_key, state)

  vim.schedule(
    function()
      if not vim.api.nvim_buf_is_valid(list_bufnr) then
        return
      end
      vim.api.nvim_buf_set_option(list_bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(list_bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(list_bufnr, "modifiable", false)
      M._changed_after()
    end
  )
end

M.start = function(source, opts)
  local candidates = source.make()
  local filter_buffer = make_filter_buffer(opts)
  local list_buffer = make_list_buffer(candidates, opts)

  if opts.insert then
    vim.api.nvim_set_current_win(filter_buffer.window)
    vim.api.nvim_command("startinsert")
  else
    vim.api.nvim_set_current_win(list_buffer.window)
  end

  local timer = nil
  local debounce = function(ms, f)
    return function()
      if timer == nil then
        timer = vim.loop.new_timer()
      end
      timer:stop()
      timer:start(ms, 0, vim.schedule_wrap(f))
    end
  end

  vim.api.nvim_buf_attach(filter_buffer.bufnr, false, {on_lines = debounce(M.debounce_ms, on_changed)})

  local on_list_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close(%s)"):format(
    list_buffer.bufnr,
    filter_buffer.window
  )
  vim.api.nvim_command(on_list_closed)

  local on_filter_closed =
    ("autocmd WinClosed <buffer=%s> lua require 'thetto/thetto'.close(%s)"):format(
    filter_buffer.bufnr,
    list_buffer.window
  )
  vim.api.nvim_command(on_filter_closed)

  vim.api.nvim_buf_set_var(
    list_buffer.bufnr,
    state_key,
    {list = list_buffer, filter = filter_buffer, kind_name = source.kind_name}
  )
  vim.api.nvim_buf_set_var(
    filter_buffer.bufnr,
    filter_state_key,
    {
      list = {bufnr = list_buffer.bufnr, window = list_buffer.window},
      filter = {bufnr = filter_buffer.bufnr, window = filter_buffer.window}
    }
  )
end

M.close = function(window_id)
  if window_id == "" then
    return
  end
  if not vim.api.nvim_win_is_valid(window_id) then
    return
  end
  vim.api.nvim_win_close(window_id, true)
end

M.execute = function(args)
  local state = vim.b[state_key]
  if vim.bo.filetype == filter_filetype then
    local filter_state = vim.b[filter_state_key]
    state = vim.api.nvim_buf_get_var(filter_state.list.bufnr, state_key)
  end
  if state == nil then
    return
  end

  local kind
  if base_kind["action_" .. args.action] ~= nil then
    kind = base_kind
  else
    kind = M.find_kind(state.kind_name)
  end
  if kind == nil then
    return vim.api.nvim_err_write("not found kind: " .. state.kind_name .. "\n")
  end

  local action = kind["action_" .. args.action]
  if action == nil then
    return vim.api.nvim_err_write("not found action: " .. args.action .. "\n")
  end

  local index = 1
  if vim.bo.filetype == filetype then
    index = vim.fn.line(".")
  end
  local candidate = state.list.filtered[index]

  if kind.options ~= nil and kind.options[args.action] then
    args = vim.tbl_extend("force", args, kind.options[args.action])
  end

  if args.quit then
    M.close(state.list.window)
  end

  local candidates = {}
  if candidate ~= nil then
    table.insert(candidates, candidate)
  end
  return action(candidates, state)
end

M.find_source = function(name)
  local path = ("thetto/source/%s"):format(name)
  local ok, source = pcall(require, path)
  if not ok then
    return nil
  end
  return source
end

M.find_kind = function(name)
  local path = ("thetto/kind/%s"):format(name)
  local ok, kind = pcall(require, path)
  if not ok then
    return nil
  end
  return kind
end

return M
