local M = {}

local state_key = "_thetto_state"

M.limit = 100

local make_list_buffer = function(candidates, opts)
  local lines = {}
  local partial = vim.tbl_values({unpack(candidates, 0, M.limit)})
  for _, candidate in pairs(partial) do
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
  vim.api.nvim_buf_set_option(bufnr, "filetype", "thetto")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  return {
    window = window_id,
    bufnr = bufnr,
    all = candidates,
    partial = partial
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
  vim.api.nvim_buf_set_option(bufnr, "filetype", "thetto-filter")

  return {
    window = window_id,
    bufnr = bufnr
  }
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

  local on_changed =
    ("autocmd TextChanged,TextChangedI <buffer=%s> lua require 'thetto/thetto'.on_changed(%s, %s)"):format(
    filter_buffer.bufnr,
    list_buffer.bufnr,
    filter_buffer.bufnr
  )
  vim.api.nvim_command(on_changed)

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
end

M.on_changed = function(list_bufnr, filter_bufnr)
  local state = vim.api.nvim_buf_get_var(list_bufnr, state_key)
  local line = vim.api.nvim_buf_get_lines(filter_bufnr, 0, 1, true)[1]
  local texts = vim.split(line, "%s")
  local lines = {}
  local partial = {}
  for _, candidate in pairs(state.list.all) do
    local ok = true
    for _, text in ipairs(texts) do
      if not (candidate.value):find(text) then
        ok = false
        break
      end
    end

    if ok then
      table.insert(partial, candidate)
    end
  end
  for _, c in pairs({unpack(partial, 0, M.limit)}) do
    table.insert(lines, c.value)
  end

  state.list.partial = partial
  vim.api.nvim_buf_set_var(list_bufnr, state_key, state)

  vim.api.nvim_buf_set_option(list_bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(list_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(list_bufnr, "modifiable", false)
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

find_kind = function(kind_name)
  local name = ("thetto/kind/%s"):format(kind_name)
  local ok, module = pcall(require, name)
  if not ok then
    return nil
  end
  return module
end

M.execute = function(action_name)
  local state = vim.b[state_key]
  if state == nil then
    return
  end

  local candidates = state.list.partial

  local kind = find_kind(state.kind_name)
  if kind == nil then
    return vim.api.nvim_err_write("not found kind: " .. state.kind_name .. "\n")
  end

  local name = action_name or "default"
  local action = kind[name]
  if action == nil then
    return vim.api.nvim_err_write("not found action: " .. name .. "\n")
  end

  local index = 1
  if vim.api.nvim_get_current_buf() == state.list.bufnr then
    index = vim.fn.line(".")
  end
  local candidate = candidates[index]

  M.close(state.list.window)

  action({candidate})
end

return M
