local highlights = require("thetto/lib/highlight")
local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local filelib = require("thetto/lib/file")
local repository = require("thetto/core/repository")

local M = {}

local UI = {}
UI.__index = UI

local input_filetype = "thetto-input"
local list_filetype = "thetto"

function UI.open(self)
  local source = self.collector.source
  local opts = self.collector.opts

  for bufnr in bufferlib.in_tabpage(0) do
    local ctx, _ = repository.get_from_path(bufnr)
    if ctx ~= nil then
      ctx.ui:close()
    end
  end

  local input_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(source.name, input_filetype))
    vim.api.nvim_buf_set_option(bufnr, "filetype", input_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, self.collector.input_lines)
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function()
        local input_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        return self.notifier:send("update_input", input_lines)
      end,
      on_detach = function()
        return self.notifier:send("finish")
      end,
    })
  end)
  local sign_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, opts.display_limit))
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)
  local list_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(source.name, list_filetype))
    vim.api.nvim_buf_set_option(bufnr, "filetype", list_filetype)
  end)
  local info_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)
  local filter_info_bufnr = bufferlib.scratch(function(_)
  end)

  self.buffers = {
    list = list_bufnr,
    sign = sign_bufnr,
    input = input_bufnr,
    info = info_bufnr,
    filter_info = filter_info_bufnr,
  }

  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/ui')._on_moved(\"%s\")"):format(list_bufnr, source.name)
  vim.api.nvim_command(on_moved)

  local sign_width = 4
  local height = math.floor(vim.o.lines * 0.5)
  local width = math.floor(vim.o.columns * 0.6)
  local row = (vim.o.lines - height) / 2
  local column = (vim.o.columns - width) / 2
  self.origin_window = vim.api.nvim_get_current_win()

  local list_window = vim.api.nvim_open_win(list_bufnr, false, {
    width = width - sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column + sign_width,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(list_window, "scrollbind", true)

  local sign_window = vim.api.nvim_open_win(sign_bufnr, false, {
    width = sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(sign_window, "winhighlight", "Normal:ThettoColorLabelBackground")
  vim.api.nvim_win_set_option(sign_window, "scrollbind", true)
  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'list')"):format(sign_bufnr, source.name)
  vim.api.nvim_command(on_sign_enter)

  local input_width = math.floor(width * 0.75)
  local input_window = vim.api.nvim_open_win(input_bufnr, false, {
    width = input_width,
    height = #self.collector.filters,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(input_window, "winhighlight", "Normal:ThettoInput,SignColumn:ThettoInput")

  local info_window = vim.api.nvim_open_win(info_bufnr, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(info_window, "winhighlight", "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo")
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'input')"):format(info_bufnr, source.name)
  vim.api.nvim_command(on_info_enter)

  local filter_info_window = vim.api.nvim_open_win(filter_info_bufnr, false, {
    width = width - input_width,
    height = #self.collector.filters,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'input')"):format(filter_info_bufnr, source.name)
  vim.api.nvim_command(on_filter_info_enter)

  local group_name = self:_close_group_name()
  vim.api.nvim_command(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/ui')._on_close(\"%s\", tonumber(vim.fn.expand('<afile>')))"):format(group_name, source.name)
  vim.api.nvim_command(on_win_closed)
  vim.api.nvim_command("augroup END")

  if self.active == "input" then
    vim.api.nvim_set_current_win(input_window)
  else
    vim.api.nvim_set_current_win(list_window)
  end
  if self.mode == "n" then
    vim.api.nvim_command("stopinsert")
  else
    vim.api.nvim_command("startinsert")
  end

  self.windows = {
    list = list_window,
    sign = sign_window,
    input = input_window,
    info = info_window,
    filter_info = filter_info_window,
  }
  self:_set_left_padding()
end

function UI._update_selections_hl(self)
  local highligher = self._selection_hl_factory:reset(self.buffers.list)
  highligher:filter("ThettoSelected", self.collector.items, function(item)
    return item.selected
  end)
end

function UI.resume(self)
  self:open()

  if self.input_cursor ~= nil then
    vim.api.nvim_win_set_cursor(self.windows.input, self.input_cursor)
    self.input_cursor = nil
  end

  return self.notifier:send("update_items", self.collector.input_lines, self.row)
end

function UI._close_group_name(self)
  return "theto_closed_" .. self.buffers.list
end

function UI.redraw(self, input_lines)
  if not vim.api.nvim_buf_is_valid(self.buffers.list) then
    return
  end
  self:_redraw_list()
  self:_redraw_info()
  self:_redraw_input(input_lines)
end

function UI._redraw_list(self)
  local collector = self.collector
  local items = collector.items
  local opts = collector.opts
  local lines = self._head_lines(items, opts.display_limit)
  vim.api.nvim_buf_set_option(self.buffers.list, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buffers.list, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.buffers.list, "modifiable", false)

  if vim.api.nvim_win_is_valid(self.windows.list) and vim.bo.filetype ~= list_filetype then
    vim.api.nvim_win_set_cursor(self.windows.list, {1, 0})
    if vim.api.nvim_win_is_valid(self.windows.sign) then
      vim.api.nvim_win_set_cursor(self.windows.sign, {1, 0})
    end
  end

  local source = collector.source
  source:highlight(self.buffers.list, items)
  source:highlight_sign(self.buffers.sign, items)
  self:_update_selections_hl()
end

function UI._redraw_input(self, input_lines)
  local items = self.collector.items
  local opts = self.collector.opts
  local filters = self.collector.filters

  if vim.api.nvim_win_is_valid(self.windows.input) then
    local input_height = #filters
    vim.api.nvim_win_set_height(self.windows.input, input_height)
    vim.api.nvim_win_set_height(self.windows.filter_info, input_height)
    vim.api.nvim_buf_set_lines(self.buffers.filter_info, 0, -1, false, vim.fn["repeat"]({""}, input_height))
  end

  local ns = vim.api.nvim_create_namespace("thetto-input-filter-info")
  input_lines = input_lines or {}
  for i, filter in ipairs(filters) do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(self.buffers.list, items, input_line, opts)
    end
    local filter_info = ("[%s]"):format(filter.name)
    vim.api.nvim_buf_set_virtual_text(self.buffers.filter_info, ns, i - 1, {
      {filter_info, "Comment"},
    }, {})
  end

  local line_count_diff = #filters - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self.buffers.input, #filters - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self.buffers.input, #filters, -1, false, {})
  end
end

function UI._redraw_info(self)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(self.collector.sorters) do
    table.insert(sorter_names, sorter.name)
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local collector_status = ""
  if not self.collector:finished() then
    collector_status = "running"
  end

  local ns = vim.api.nvim_create_namespace("thetto-info-text")
  vim.api.nvim_buf_clear_namespace(self.buffers.info, ns, 0, -1)
  local text = ("%s%s  [ %s / %s ]"):format(self.collector.source.name, sorter_info, vim.tbl_count(self.collector.items), #self.collector.all_items)
  vim.api.nvim_buf_set_virtual_text(self.buffers.info, ns, 0, {
    {text, "ThettoInfo"},
    {"  " .. collector_status, "Comment"},
  }, {})
end

function UI.update_offset(self, offset)
  local row = self.row + offset
  local line_count = #self.collector.items
  if self.collector.opts.display_limit < line_count then
    line_count = self.collector.opts.display_limit
  end
  if line_count < row then
    row = line_count
  elseif row < 1 then
    row = 1
  end
  self.row = row
end

function UI.close(self)
  if vim.api.nvim_win_is_valid(self.windows.list) then
    self.row = vim.api.nvim_win_get_cursor(self.windows.list)[1]
    local active = "input"
    if vim.api.nvim_get_current_win() == self.windows.list then
      active = "list"
    end
    self.active = active
    self.mode = vim.api.nvim_get_mode().mode
  end

  if vim.api.nvim_win_is_valid(self.windows.input) then
    self.input_cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  end

  for _, id in pairs(self.windows) do
    windowlib.close(id)
  end
  self:close_preview()
  vim.api.nvim_command("autocmd! " .. self:_close_group_name())

  if vim.api.nvim_win_is_valid(self.origin_window) then
    vim.api.nvim_set_current_win(self.origin_window)
  end

  self.notifier:send("finish")
end

function UI.enter(self, to)
  windowlib.enter(self.windows[to])
end

function UI.current_position_filter(self)
  local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  return self.collector.filters[cursor[1]]
end

function UI.current_position_sorter(self)
  local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
  return self.collector.sorters[cursor[1]]
end

function UI.start_insert(self, behavior)
  vim.api.nvim_command("startinsert")
  if behavior == "a" then
    local max_col = vim.fn.col("$")
    local cursor = vim.api.nvim_win_get_cursor(self.windows.input)
    if cursor[2] ~= max_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(self.windows.input, cursor)
    end
  end
end

function UI.selected_items(self, action_name, range)
  range = range or {}

  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self.collector.selected) then
    local selected = vim.tbl_values(self.collector.selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  if range.given and vim.bo.filetype == list_filetype then
    local items = {}
    for i = range.first, range.last, 1 do
      table.insert(items, self.collector.items[i])
    end
    return items
  end

  local index
  local filetype = vim.bo.filetype
  if filetype == input_filetype then
    index = 1
  elseif vim.bo.filetype == list_filetype then
    index = vim.fn.line(".")
  else
    index = self.row
  end
  return {self.collector.items[index]}
end

function UI.open_preview(self, open_target)
  local list_config = vim.api.nvim_win_get_config(self.windows.list)
  local height = list_config.height + #self.collector.filters + 1
  local half_height = math.floor(height / 2)

  local top_row = 1
  local row = open_target.row
  if open_target.row ~= nil and open_target.row > half_height then
    top_row = open_target.row - half_height + 1
    row = half_height
  end

  local lines
  if open_target.bufnr ~= nil then
    lines = vim.api.nvim_buf_get_lines(open_target.bufnr, top_row - 1, top_row + height - 1, false)
  elseif open_target.path ~= nil then
    lines = filelib.read_lines(open_target.path, top_row, top_row + height)
  else
    lines = {}
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  local input_config = vim.api.nvim_win_get_config(self.windows.input)
  local info_config = vim.api.nvim_win_get_config(self.windows.info)
  local sign_config = vim.api.nvim_win_get_config(self.windows.sign)
  local filter_info_config = vim.api.nvim_win_get_config(self.windows.filter_info)
  local left_column = 7
  vim.api.nvim_win_set_config(self.windows.list, {
    relative = "editor",
    col = left_column + sign_config.width,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self.windows.sign, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self.windows.info, {
    relative = "editor",
    col = left_column,
    row = info_config.row,
  })
  vim.api.nvim_win_set_config(self.windows.input, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
  vim.api.nvim_win_set_config(self.windows.filter_info, {
    relative = "editor",
    col = left_column + input_config.width,
    row = filter_info_config.row,
  })

  self:_set_left_padding()

  if not self:opened_preview() then
    self.preview_window = vim.api.nvim_open_win(bufnr, false, {
      width = vim.o.columns - left_column - input_config.width - filter_info_config.width - 3,
      height = height,
      relative = "editor",
      row = list_config.row,
      col = left_column + input_config.width + filter_info_config.width + 1,
      focusable = false,
      external = false,
      style = "minimal",
    })
    vim.api.nvim_win_set_option(self.preview_window, "scrollbind", false)
  else
    vim.api.nvim_win_set_buf(self.preview_window, bufnr)
  end

  if row ~= nil then
    local highlighter = self._preview_hl_factory:create(bufnr)
    local range = open_target.range or {s = {column = 0}, e = {column = -1}}
    highlighter:add("ThettoPreview", row - 1, range.s.column, range.e.column)
  end
end

function UI.opened_preview(self)
  if self.preview_window == nil then
    return false
  end
  return vim.api.nvim_win_is_valid(self.preview_window)
end

function UI.close_preview(self)
  if self.preview_window ~= nil then
    windowlib.close(self.preview_window)
  end

  if vim.api.nvim_win_is_valid(self.windows.list) then
    local list_config = vim.api.nvim_win_get_config(self.windows.list)
    local column = (vim.o.columns - list_config.width) / 2
    local input_config = vim.api.nvim_win_get_config(self.windows.input)
    local info_config = vim.api.nvim_win_get_config(self.windows.info)
    local sign_config = vim.api.nvim_win_get_config(self.windows.sign)
    local filter_info_config = vim.api.nvim_win_get_config(self.windows.filter_info)
    vim.api.nvim_win_set_config(self.windows.list, {
      relative = "editor",
      col = column + sign_config.width,
      row = list_config.row,
    })
    vim.api.nvim_win_set_config(self.windows.sign, {
      relative = "editor",
      col = column,
      row = list_config.row,
    })
    vim.api.nvim_win_set_config(self.windows.info, {
      relative = "editor",
      col = column,
      row = info_config.row,
    })
    vim.api.nvim_win_set_config(self.windows.input, {
      relative = "editor",
      col = column,
      row = input_config.row,
    })
    vim.api.nvim_win_set_config(self.windows.filter_info, {
      relative = "editor",
      col = column + input_config.width,
      row = filter_info_config.row,
    })

    self:_set_left_padding()
  end
end

function UI._head_lines(items)
  local lines = {}
  for _, item in pairs(items) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function UI._set_left_padding(self)
  vim.api.nvim_win_set_option(self.windows.input, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(self.windows.info, "signcolumn", "yes:1")
end

M.new = function(collector, notifier)
  local tbl = {
    collector = collector,
    notifier = notifier,
    windows = {},
    buffers = {},
    row = 1,
    input_cursor = nil,
  }

  if collector.opts.insert then
    tbl.active = "input"
    tbl.mode = "i"
  else
    tbl.active = "list"
    tbl.mode = "n"
  end

  tbl._selection_hl_factory = highlights.new_factory("thetto-selection-highlight")
  tbl._preview_hl_factory = highlights.new_factory("thetto-preview")

  vim.api.nvim_command("highlight default link ThettoSelected Statement")
  vim.api.nvim_command("highlight default link ThettoPreview Search")
  vim.api.nvim_command("highlight default link ThettoInfo StatusLine")
  vim.api.nvim_command("highlight default link ThettoColorLabelOthers StatusLine")
  vim.api.nvim_command("highlight default link ThettoColorLabelBackground NormalFloat")
  vim.api.nvim_command("highlight default link ThettoInput NormalFloat")

  local self = setmetatable(tbl, UI)

  self.notifier:on("update_items", function(input_lines, row)
    local err = self:redraw(input_lines)
    if err ~= nil then
      return err
    end
    if row ~= nil then
      vim.api.nvim_win_set_cursor(self.windows.list, {row, 0})
    end
    err = self.notifier:send("execute")
    if err ~= nil then
      return err
    end
    M._changed_after(input_lines)
  end)

  self.notifier:on("update_selected", function()
    self:_update_selections_hl()
  end)

  self.notifier:on("close", function()
    self:close()
  end)

  return self
end

M._on_close = function(key, id)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end

  local ok = false
  for _, window in pairs(ui.windows) do
    if window == id then
      ok = true
    end
  end
  if not ok then
    return
  end

  ui:close()
end

M._on_enter = function(key, to)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:enter(to)
end

M._on_moved = function(key)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui.notifier:send("execute")
end

-- for testing
M._changed_after = function(_)
end

return M
