local states = require("thetto/core/state")
local highlights = require("thetto/view/highlight")
local windowlib = require "thetto/lib/window"

local M = {}

M.close_callbacks = {}

M.open = function(buffers, resumed_state, opts, on_closed)
  local ids = vim.api.nvim_tabpage_list_wins(0)
  for _, id in ipairs(ids) do
    local bufnr = vim.fn.winbufnr(id)
    if bufnr == -1 then
      goto continue
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path:match(states.path_pattern) then
      M.close(id)
    end
    ::continue::
  end

  local sign_width = 4
  local row = vim.o.lines / 2 - ((opts.height + 2) / 2)
  local column = vim.o.columns / 2 - (opts.width / 2)
  local origin_window = vim.api.nvim_get_current_win()

  local list_window = vim.api.nvim_open_win(buffers.list, false, {
    width = opts.width - sign_width,
    height = opts.height,
    relative = "editor",
    row = row,
    col = column + sign_width,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(list_window, "scrollbind", true)

  local sign_window = vim.api.nvim_open_win(buffers.sign, false, {
    width = sign_width,
    height = opts.height,
    relative = "editor",
    row = row,
    col = column,
    focusable = false,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(sign_window, "winhighlight", "Normal:ThettoColorLabelBackground")
  vim.api.nvim_win_set_option(sign_window, "scrollbind", true)

  local info_window = vim.api.nvim_open_win(buffers.info, false, {
    width = opts.width,
    height = 1,
    relative = "editor",
    row = row + opts.height,
    col = column,
    focusable = false,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(info_window, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(info_window, "winhighlight", "Normal:ThettoInfo,SignColumn:ThettoInfo")

  local input_width = opts.width * 0.75
  local input_window = vim.api.nvim_open_win(buffers.input, false, {
    width = input_width,
    height = #buffers.filters,
    relative = "editor",
    row = row + opts.height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(input_window, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(input_window, "winhighlight", "SignColumn:NormalFloat")

  local filter_info_window = vim.api.nvim_open_win(buffers.filter_info, false, {
    width = opts.width - input_width,
    height = #buffers.filters,
    relative = "editor",
    row = row + opts.height + 1,
    col = column + input_width,
    focusable = false,
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

  M.close_callbacks[list_window] = on_closed
  M.close_callbacks[input_window] = on_closed

  local on_list_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/view/ui'.close(%s, %s, %s, %s, vim.fn.expand('<afile>'))"):format(buffers.list, info_window, input_window, sign_window, filter_info_window)
  vim.api.nvim_command(on_list_closed)

  local on_sign_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/view/ui'.close(%s, %s, %s, %s, vim.fn.expand('<afile>'))"):format(buffers.sign, input_window, list_window, info_window, filter_info_window)
  vim.api.nvim_command(on_sign_closed)

  local on_input_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/view/ui'.close(%s, %s, %s, %s, vim.fn.expand('<afile>'))"):format(buffers.input, info_window, list_window, sign_window, filter_info_window)
  vim.api.nvim_command(on_input_closed)

  local on_info_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/view/ui'.close(%s, %s, %s, %s, vim.fn.expand('<afile>'))"):format(buffers.info, input_window, list_window, sign_window, filter_info_window)
  vim.api.nvim_command(on_info_closed)

  local on_filter_info_closed = ("autocmd WinClosed <buffer=%s> lua require 'thetto/view/ui'.close(%s, %s, %s, %s, vim.fn.expand('<afile>'))"):format(buffers.filter_info, input_window, list_window, sign_window, list_window)
  vim.api.nvim_command(on_filter_info_closed)

  local insert = opts.insert
  if resumed_state ~= nil and resumed_state.windows.active == "list" then
    insert = false
  end
  if insert then
    vim.api.nvim_set_current_win(input_window)
    if resumed_state ~= nil and resumed_state.windows.mode == "n" then
      vim.api.nvim_command("stopinsert")
    else
      vim.api.nvim_command("startinsert")
    end
  else
    vim.api.nvim_set_current_win(list_window)
  end

  return {
    list = list_window,
    input = input_window,
    info = info_window,
    sign = sign_window,
    filter_info = filter_info_window,
    origin = origin_window,
  }
end

M.render = function(source, items, all_items_count, buffers, windows, filters, input_lines, sorters, opts)
  if not vim.api.nvim_buf_is_valid(buffers.list) then
    return
  end

  local lines = M._head_lines(items, opts.display_limit)
  vim.api.nvim_buf_set_option(buffers.list, "modifiable", true)
  vim.api.nvim_buf_set_lines(buffers.list, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buffers.list, "modifiable", false)

  M._render_info(buffers.info, items, all_items_count, source.name, sorters)

  if vim.api.nvim_win_is_valid(windows.list) and vim.bo.filetype ~= states.list_filetype then
    vim.api.nvim_win_set_cursor(windows.list, {1, 0})
    if vim.api.nvim_win_is_valid(windows.sign) then
      vim.api.nvim_win_set_cursor(windows.sign, {1, 0})
    end
  end

  source:highlight(buffers.list, items)
  source:highlight_sign(buffers.sign, items)
  highlights.update_selections(buffers.list, items)

  if vim.api.nvim_win_is_valid(windows.input) then
    local input_height = #filters
    vim.api.nvim_win_set_height(windows.input, input_height)
    vim.api.nvim_win_set_height(windows.filter_info, input_height)
    vim.api.nvim_buf_set_lines(buffers.filter_info, 0, -1, false, vim.fn["repeat"]({""}, input_height))
  end

  local ns = vim.api.nvim_create_namespace("thetto-input-filter-info")
  for i, filter in ipairs(filters) do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(buffers.list, items, input_line, opts)
    end
    local filter_info = ("[%s]"):format(filter.name)
    vim.api.nvim_buf_set_virtual_text(buffers.filter_info, ns, i - 1, {{filter_info, "Comment"}}, {})
  end

  local line_count_diff = #filters - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(buffers.input, #filters - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(buffers.input, #filters, -1, false, {})
  end
end

M._render_info = function(bufnr, items, all_items_count, source_name, sorters)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(sorters) do
    table.insert(sorter_names, sorter:get_name())
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local ns = vim.api.nvim_create_namespace("thetto-info-text")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local text = ("%s%s  [ %s / %s ]"):format(source_name, sorter_info, vim.tbl_count(items), all_items_count)
  vim.api.nvim_buf_set_virtual_text(bufnr, ns, 0, {{text, "ThettoInfo"}}, {})
end

M.close = function(...)
  for _, id in ipairs({...}) do
    windowlib.close(id)
    local on_closed = M.close_callbacks[id]
    if on_closed ~= nil then
      on_closed(id)
      M.close_callbacks[id] = nil
    end
  end
end

M._head_lines = function(items)
  local lines = {}
  for _, item in pairs(items) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

return M
