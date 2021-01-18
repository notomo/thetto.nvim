local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local filelib = require("thetto/lib/file")
local highlights = require("thetto/lib/highlight")
local repository = require("thetto/core/repository")
local vim = vim

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

function WindowGroup.enter(self, to)
  windowlib.enter(self[to])
end

function WindowGroup.open_sidecar(self, collector, item, open_target)
  if not vim.api.nvim_win_is_valid(self.list) then
    return
  end
  if open_target.bufnr ~= nil and not vim.api.nvim_buf_is_valid(open_target.bufnr) then
    return
  end

  local list_config = vim.api.nvim_win_get_config(self.list)
  local height = list_config.height + collector.filters:length() + 1
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
  elseif open_target.lines ~= nil then
    lines = open_target.lines
  else
    lines = {}
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"

  local left_column = 2
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
    vim.wo[self.sidecar].scrollbind = false
  else
    vim.api.nvim_win_set_buf(self.sidecar, bufnr)
  end

  local index
  if item then
    index = item.index
  end
  self._sidecar_index = index

  if open_target.execute ~= nil then
    local origin = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(self.sidecar)
    open_target.execute()
    vim.api.nvim_set_current_win(origin)
  end

  if row ~= nil then
    local highlighter = self._preview_hl_factory:create(bufnr)
    local range = open_target.range or {s = {column = 0}, e = {column = -1}}
    highlighter:add("ThettoPreview", row - 1, range.s.column, range.e.column)
    if vim.fn.getbufline(bufnr, row)[1] == "" then
      highlighter:set_virtual_text(row - 1, {{"(empty)", "ThettoPreview"}})
    end
  end
end

function WindowGroup.opened_sidecar(self)
  return self.sidecar ~= nil and vim.api.nvim_win_is_valid(self.sidecar)
end

function WindowGroup.exists_same_sidecar(self, item)
  if not self:opened_sidecar() then
    return false
  end
  return item ~= nil and item.index == self._sidecar_index
end

function WindowGroup.close_sidecar(self)
  if self.sidecar ~= nil then
    windowlib.close(self.sidecar)
    self.sidecar = nil
    self._sidecar_index = nil
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
  vim.cmd("autocmd! " .. self:_close_group_name())
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

function WindowGroup._open(self, default_input_lines, active)
  local input_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(self.source_name, input_filetype))
    vim.bo[bufnr].filetype = input_filetype
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, default_input_lines)
    self.notifier:send("setup_input", bufnr)
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function()
        return self.notifier:send("update_input")
      end,
      on_detach = function()
        return self.notifier:send("finish")
      end,
    })
  end)
  local sign_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, self._display_limit))
    vim.bo[bufnr].modifiable = false
  end)
  local list_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(self.source_name, list_filetype))
    vim.bo[bufnr].filetype = list_filetype
  end)
  local info_bufnr = bufferlib.scratch(function(bufnr)
    vim.bo[bufnr].modifiable = false
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
  local row = (vim.o.lines - height - #default_input_lines) / 2
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
  vim.wo[list_window].scrollbind = true

  local sign_window = vim.api.nvim_open_win(self.buffers.sign, false, {
    width = sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[sign_window].winhighlight = "Normal:ThettoColorLabelBackground"
  vim.wo[sign_window].scrollbind = true
  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'list')"):format(self.buffers.sign, self.source_name)
  vim.cmd(on_sign_enter)

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
  vim.wo[input_window].winhighlight = "Normal:ThettoInput,SignColumn:ThettoInput,CursorLine:ThettoInput"

  local info_window = vim.api.nvim_open_win(self.buffers.info, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[info_window].winhighlight = "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo"
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'input')"):format(self.buffers.info, self.source_name)
  vim.cmd(on_info_enter)

  local filter_info_window = vim.api.nvim_open_win(self.buffers.filter_info, false, {
    width = width - input_width,
    height = #lines,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'input')"):format(self.buffers.filter_info, self.source_name)
  vim.cmd(on_filter_info_enter)

  local group_name = self:_close_group_name()
  vim.cmd(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/window_group')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"):format(group_name, self.source_name)
  vim.cmd(on_win_closed)
  vim.cmd("augroup END")

  self.list = list_window
  self.sign = sign_window
  self.input = input_window
  self.info = info_window
  self.filter_info = filter_info_window
  self.windows = {self.list, self.sign, self.input, self.info, self.filter_info}

  self:_set_left_padding()

  self:enter(active)

  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/window_group')._on_moved('%s')"):format(self.buffers.list, self.source_name)
  vim.cmd(on_moved)

  local on_moved_i = ("autocmd CursorMovedI <buffer=%s> stopinsert"):format(self.buffers.list)
  vim.cmd(on_moved_i)
end

function WindowGroup._redraw_list(self, collector)
  local items = collector.items
  local opts = collector.opts
  local lines = self._head_lines(items, opts.display_limit)
  vim.bo[self.buffers.list].modifiable = true
  vim.api.nvim_buf_set_lines(self.buffers.list, 0, -1, false, lines)
  vim.bo[self.buffers.list].modifiable = false

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
  local height = collector.filters:length()

  if vim.api.nvim_win_is_valid(self.input) then
    vim.api.nvim_win_set_height(self.input, height)
    vim.api.nvim_win_set_height(self.filter_info, height)
    vim.api.nvim_buf_set_lines(self.buffers.filter_info, 0, -1, false, vim.fn["repeat"]({""}, height))
  end

  local highlighter = self._info_hl_factory:reset(self.buffers.filter_info)
  for i, filter in filters:iter() do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(self.buffers.list, items, input_line, opts)
    end
    local filter_info = ("[%s]"):format(filter.name)
    highlighter:set_virtual_text(i - 1, {{filter_info, "ThettoFilterInfo"}})
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self.buffers.input, height - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self.buffers.input, height, -1, false, {})
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

  local text = ("%s%s  [ %s / %s ]"):format(collector.source.name, sorter_info, vim.tbl_count(collector.items), collector.result:count())
  local highlighter = self._info_hl_factory:reset(self.buffers.info)
  highlighter:set_virtual_text(0, {{text, "ThettoInfo"}, {"  " .. collector_status, "Comment"}})
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function WindowGroup._set_left_padding(self)
  vim.wo[self.input].signcolumn = "yes:1"
  vim.wo[self.info].signcolumn = "yes:1"
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

M.open = function(notifier, source_name, default_input_lines, display_limit, active)
  local tbl = {notifier = notifier, source_name = source_name, _display_limit = display_limit}
  tbl._selection_hl_factory = highlights.new_factory("thetto-selection-highlight")
  tbl._preview_hl_factory = highlights.new_factory("thetto-preview")
  tbl._info_hl_factory = highlights.new_factory("thetto-info-text")
  tbl._filter_info_hl_factory = highlights.new_factory("thetto-input-filter-info")

  local window_group = setmetatable(tbl, WindowGroup)
  window_group:_open(default_input_lines, active)
  return window_group
end

M._on_close = function(key, id)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  if not ui.windows:has(id) then
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

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
