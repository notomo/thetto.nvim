local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local filelib = require("thetto/lib/file")
local highlights = require("thetto/lib/highlight")

local input_filetype = "thetto-input"
local list_filetype = "thetto"

local get_width = function()
  return math.floor(vim.o.columns * 0.6)
end

local get_column = function()
  return (vim.o.columns - get_width()) / 2
end

local M = {}

local WindowGroup = {}
WindowGroup.__index = WindowGroup

function WindowGroup.is_current(self, name)
  local bufnr = self.buffers[name]
  return vim.api.nvim_get_current_buf() == bufnr
end

function WindowGroup.open_sidecar(self, collector, open_target)
  if not vim.api.nvim_win_is_valid(self.list) then
    return
  end

  local list_config = vim.api.nvim_win_get_config(self.list)
  local height = list_config.height + #collector.filters + 1
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

  local left_column = 7
  self:move_to(left_column)

  if not self:opened_sidecar() then
    local width = get_width()
    self.sidecar = vim.api.nvim_open_win(bufnr, false, {
      width = vim.o.columns - left_column - width - 3,
      height = height,
      relative = "editor",
      row = list_config.row,
      col = left_column + width + 1,
      focusable = false,
      external = false,
      style = "minimal",
    })
    vim.api.nvim_win_set_option(self.sidecar, "scrollbind", false)
  else
    vim.api.nvim_win_set_buf(self.sidecar, bufnr)
  end

  if row ~= nil then
    local highlighter = self._preview_hl_factory:create(bufnr)
    local range = open_target.range or {s = {column = 0}, e = {column = -1}}
    highlighter:add("ThettoPreview", row - 1, range.s.column, range.e.column)
  end
end

function WindowGroup.opened_sidecar(self)
  if self.sidecar == nil then
    return false
  end
  return vim.api.nvim_win_is_valid(self.sidecar)
end

function WindowGroup.close_sidecar(self)
  if self.sidecar ~= nil then
    windowlib.close(self.sidecar)
    self:reset_position()
  end
end

function WindowGroup.redraw_selections(self, collector)
  local highligher = self._selection_hl_factory:reset(self.buffers.list)
  highligher:filter("ThettoSelected", collector.items, function(item)
    return item.selected
  end)
end

function WindowGroup.has(self, window_id)
  for _, id in ipairs(self.windows) do
    if window_id == id then
      return true
    end
  end
  return false
end

function WindowGroup.close(self)
  for _, id in pairs(self.windows) do
    windowlib.close(id)
  end
  self:close_sidecar()
  vim.api.nvim_command("autocmd! " .. self:_close_group_name())
end

function WindowGroup.move_to(self, left_column)
  local list_config = vim.api.nvim_win_get_config(self.list)
  local input_config = vim.api.nvim_win_get_config(self.input)
  local info_config = vim.api.nvim_win_get_config(self.info)
  local sign_config = vim.api.nvim_win_get_config(self.sign)
  local filter_info_config = vim.api.nvim_win_get_config(self.filter_info)
  vim.api.nvim_win_set_config(self.list, {
    relative = "editor",
    col = left_column + sign_config.width,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self.sign, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self.info, {
    relative = "editor",
    col = left_column,
    row = info_config.row,
  })
  vim.api.nvim_win_set_config(self.input, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
  vim.api.nvim_win_set_config(self.filter_info, {
    relative = "editor",
    col = left_column + input_config.width,
    row = filter_info_config.row,
  })

  self:_set_left_padding()
end

function WindowGroup.reset_position(self)
  if not vim.api.nvim_win_is_valid(self.list) then
    return
  end
  self:move_to(get_column())
end

function WindowGroup.redraw(self, collector, input_lines)
  if not vim.api.nvim_buf_is_valid(self.buffers.list) then
    return
  end
  self:_redraw_list(collector)
  self:_redraw_info(collector)
  self:_redraw_input(collector, input_lines)
end

function WindowGroup._open(self, default_input_lines)
  local input_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(self.source_name, input_filetype))
    vim.api.nvim_buf_set_option(bufnr, "filetype", input_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, default_input_lines)
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
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, self._display_limit))
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)
  local list_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(self.source_name, list_filetype))
    vim.api.nvim_buf_set_option(bufnr, "filetype", list_filetype)
  end)
  local info_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)
  local filter_info_bufnr = bufferlib.scratch(function(_)
  end)
  self.buffers = {
    input = input_bufnr,
    sign = sign_bufnr,
    list = list_bufnr,
    info = info_bufnr,
    filter_info = filter_info_bufnr,
  }

  local sign_width = 4
  local height = math.floor(vim.o.lines * 0.5)
  local width = get_width()
  local row = (vim.o.lines - height) / 2
  local column = get_column()

  local list_window = vim.api.nvim_open_win(self.buffers.list, false, {
    width = width - sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column + sign_width,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(list_window, "scrollbind", true)

  local sign_window = vim.api.nvim_open_win(self.buffers.sign, false, {
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
  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'list')"):format(self.buffers.sign, self.source_name)
  vim.api.nvim_command(on_sign_enter)

  local lines = vim.api.nvim_buf_get_lines(self.buffers.input, 0, -1, false)
  local input_width = math.floor(width * 0.75)
  local input_window = vim.api.nvim_open_win(self.buffers.input, false, {
    width = input_width,
    height = #lines,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(input_window, "winhighlight", "Normal:ThettoInput,SignColumn:ThettoInput")

  local info_window = vim.api.nvim_open_win(self.buffers.info, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(info_window, "winhighlight", "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo")
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'input')"):format(self.buffers.info, self.source_name)
  vim.api.nvim_command(on_info_enter)

  local filter_info_window = vim.api.nvim_open_win(self.buffers.filter_info, false, {
    width = width - input_width,
    height = #lines,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('%s', 'input')"):format(self.buffers.filter_info, self.source_name)
  vim.api.nvim_command(on_filter_info_enter)

  local group_name = self:_close_group_name()
  vim.api.nvim_command(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/ui')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"):format(group_name, self.source_name)
  vim.api.nvim_command(on_win_closed)
  vim.api.nvim_command("augroup END")

  self.list = list_window
  self.sign = sign_window
  self.input = input_window
  self.info = info_window
  self.filter_info = filter_info_window
  self.windows = {self.list, self.sign, self.input, self.info, self.filter_info}

  self:_set_left_padding()

  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/ui')._on_moved(\"%s\")"):format(self.buffers.list, self.source_name)
  vim.api.nvim_command(on_moved)
end

function WindowGroup._redraw_list(self, collector)
  local items = collector.items
  local opts = collector.opts
  local lines = self._head_lines(items, opts.display_limit)
  vim.api.nvim_buf_set_option(self.buffers.list, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.buffers.list, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.buffers.list, "modifiable", false)

  if vim.api.nvim_win_is_valid(self.list) and vim.api.nvim_get_current_buf() ~= self.buffers.list then
    vim.api.nvim_win_set_cursor(self.list, {1, 0})
    if vim.api.nvim_win_is_valid(self.sign) then
      vim.api.nvim_win_set_cursor(self.sign, {1, 0})
    end
  end

  local source = collector.source
  source:highlight(self.buffers.list, items)
  source:highlight_sign(self.buffers.sign, items)
  self:redraw_selections(collector)
end

function WindowGroup._redraw_input(self, collector, input_lines)
  local items = collector.items
  local opts = collector.opts
  local filters = collector.filters

  if vim.api.nvim_win_is_valid(self.input) then
    local input_height = #filters
    vim.api.nvim_win_set_height(self.input, input_height)
    vim.api.nvim_win_set_height(self.filter_info, input_height)
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

function WindowGroup._redraw_info(self, collector)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(collector.sorters) do
    table.insert(sorter_names, sorter.name)
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local collector_status = ""
  if not collector:finished() then
    collector_status = "running"
  end

  local ns = vim.api.nvim_create_namespace("thetto-info-text")
  vim.api.nvim_buf_clear_namespace(self.buffers.info, ns, 0, -1)
  local text = ("%s%s  [ %s / %s ]"):format(collector.source.name, sorter_info, vim.tbl_count(collector.items), #collector.all_items)
  vim.api.nvim_buf_set_virtual_text(self.buffers.info, ns, 0, {
    {text, "ThettoInfo"},
    {"  " .. collector_status, "Comment"},
  }, {})
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function WindowGroup._set_left_padding(self)
  vim.api.nvim_win_set_option(self.input, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(self.info, "signcolumn", "yes:1")
end

function WindowGroup._close_group_name(self)
  return "theto_closed_" .. self.buffers.list
end

function WindowGroup._head_lines(items)
  local lines = {}
  for _, item in pairs(items) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

M.open = function(notifier, source_name, default_input_lines, display_limit)
  local tbl = {notifier = notifier, source_name = source_name, _display_limit = display_limit}
  tbl._selection_hl_factory = highlights.new_factory("thetto-selection-highlight")
  tbl._preview_hl_factory = highlights.new_factory("thetto-preview")

  local window_group = setmetatable(tbl, WindowGroup)
  window_group:_open(default_input_lines)
  return window_group
end

vim.api.nvim_command("highlight default link ThettoSelected Statement")
vim.api.nvim_command("highlight default link ThettoInfo StatusLine")
vim.api.nvim_command("highlight default link ThettoColorLabelOthers StatusLine")
vim.api.nvim_command("highlight default link ThettoColorLabelBackground NormalFloat")
vim.api.nvim_command("highlight default link ThettoInput NormalFloat")
vim.api.nvim_command("highlight default link ThettoPreview Search")

return M
