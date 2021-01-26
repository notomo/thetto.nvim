local windowlib = require("thetto/lib/window")
local cursorlib = require("thetto/lib/cursor")
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
M.WindowGroup = WindowGroup

function WindowGroup.open(collector, active)
  local tbl = {
    _display_limit = collector.opts.display_limit,
    _selection_hl_factory = highlights.new_factory("thetto-selection-highlight"),
    _preview_hl_factory = highlights.new_factory("thetto-preview"),
    _info_hl_factory = highlights.new_factory("thetto-info-text"),
    _filter_info_hl_factory = highlights.new_factory("thetto-input-filter-info"),
    _filter_height = 0,
  }

  local self = setmetatable(tbl, WindowGroup)

  local source_name = collector.source.name
  local input_lines = collector.input_lines

  local input_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(source_name, input_filetype))
    vim.bo[bufnr].filetype = input_filetype
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, input_lines)
    collector:attach(bufnr)
    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function()
        return collector:update_with_debounce()
      end,
      on_detach = function()
        return collector:discard()
      end,
    })
  end)
  local sign_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, self._display_limit))
    vim.bo[bufnr].modifiable = false
  end)
  local list_bufnr = bufferlib.scratch(function(bufnr)
    vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/%s"):format(source_name, list_filetype))
    vim.bo[bufnr].filetype = list_filetype
  end)
  local info_bufnr = bufferlib.scratch(function(bufnr)
    vim.bo[bufnr].modifiable = false
  end)
  local filter_info_bufnr = bufferlib.scratch(function(_)
  end)
  self._buffers = {
    input = input_bufnr,
    sign = sign_bufnr,
    list = list_bufnr,
    info = info_bufnr,
    filter_info = filter_info_bufnr,
  }

  local sign_width = 4
  local height = math.floor(vim.o.lines * 0.5)
  local width = get_width()
  local row = (vim.o.lines - height - #input_lines) / 2
  local column = get_column()

  local list_window = vim.api.nvim_open_win(self._buffers.list, false, {
    width = width - sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column + sign_width,
    external = false,
    style = "minimal",
  })
  vim.wo[list_window].scrollbind = true

  local sign_window = vim.api.nvim_open_win(self._buffers.sign, false, {
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
  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'list')"):format(self._buffers.sign, source_name)
  vim.cmd(on_sign_enter)

  local lines = vim.api.nvim_buf_get_lines(self._buffers.input, 0, -1, false)
  local input_width = math.floor(width * 0.75)
  local input_window = vim.api.nvim_open_win(self._buffers.input, false, {
    width = input_width,
    height = #lines,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[input_window].winhighlight = "Normal:ThettoInput,SignColumn:ThettoInput,CursorLine:ThettoInput"

  local info_window = vim.api.nvim_open_win(self._buffers.info, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[info_window].winhighlight = "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo"
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'input')"):format(self._buffers.info, source_name)
  vim.cmd(on_info_enter)

  local filter_info_window = vim.api.nvim_open_win(self._buffers.filter_info, false, {
    width = width - input_width,
    height = #lines,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/window_group')._on_enter('%s', 'input')"):format(self._buffers.filter_info, source_name)
  vim.cmd(on_filter_info_enter)

  local group_name = self:_close_group_name()
  vim.cmd(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/window_group')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"):format(group_name, source_name)
  vim.cmd(on_win_closed)
  vim.cmd("augroup END")

  self.list = list_window
  self._sign = sign_window
  self.input = input_window
  self._info = info_window
  self._filter_info = filter_info_window
  self._windows = {self.list, self._sign, self.input, self._info, self._filter_info}

  self:_set_left_padding()

  self:enter(active)

  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/window_group')._on_moved('%s')"):format(self._buffers.list, source_name)
  vim.cmd(on_moved)

  local on_moved_i = ("autocmd CursorMovedI <buffer=%s> stopinsert"):format(self._buffers.list)
  vim.cmd(on_moved_i)

  return self
end

function WindowGroup.is_current(self, name)
  local bufnr = self._buffers[name]
  return vim.api.nvim_get_current_buf() == bufnr
end

function WindowGroup.enter(self, to)
  windowlib.enter(self[to])
end

function WindowGroup.open_sidecar(self, item, open_target)
  if not vim.api.nvim_win_is_valid(self.list) then
    return
  end
  if open_target.bufnr ~= nil and not vim.api.nvim_buf_is_valid(open_target.bufnr) then
    return
  end

  local list_config = vim.api.nvim_win_get_config(self.list)
  local height = list_config.height + self._filter_height + 1
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

function WindowGroup.redraw_selections(self, items)
  local highligher = self._selection_hl_factory:reset(self._buffers.list)
  highligher:filter("ThettoSelected", items, function(item)
    return item.selected
  end)
end

function WindowGroup.has(self, window_id)
  for _, id in ipairs(self._windows) do
    if window_id == id then
      return true
    end
  end
  return false
end

function WindowGroup.close(self)
  for _, id in pairs(self._windows) do
    windowlib.close(id)
  end
  self:close_sidecar()
  vim.cmd("autocmd! " .. self:_close_group_name())
end

function WindowGroup.move_to(self, left_column)
  local list_config = vim.api.nvim_win_get_config(self.list)
  local input_config = vim.api.nvim_win_get_config(self.input)
  local info_config = vim.api.nvim_win_get_config(self._info)
  local sign_config = vim.api.nvim_win_get_config(self._sign)
  local filter_info_config = vim.api.nvim_win_get_config(self._filter_info)
  vim.api.nvim_win_set_config(self.list, {
    relative = "editor",
    col = left_column + sign_config.width,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self._sign, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self._info, {
    relative = "editor",
    col = left_column,
    row = info_config.row,
  })
  vim.api.nvim_win_set_config(self.input, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
  vim.api.nvim_win_set_config(self._filter_info, {
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

function WindowGroup.set_row(self, row)
  cursorlib.set_row(row, self.list, self._buffers.list)
end

function WindowGroup.redraw(self, draw_ctx)
  if not vim.api.nvim_buf_is_valid(self._buffers.list) then
    return
  end

  local items = draw_ctx.items
  local source = draw_ctx.source

  self:_redraw_list(items, source)
  self:_redraw_info(source, items, draw_ctx.sorters, draw_ctx.finished, draw_ctx.result_count)
  self:_redraw_input(draw_ctx.input_lines, items, draw_ctx.filters, draw_ctx.opts)
end

function WindowGroup._redraw_list(self, items, source)
  local lines = self._head_lines(items, self._display_limit)
  vim.bo[self._buffers.list].modifiable = true
  vim.api.nvim_buf_set_lines(self._buffers.list, 0, -1, false, lines)
  vim.bo[self._buffers.list].modifiable = false

  if vim.api.nvim_win_is_valid(self.list) and vim.api.nvim_get_current_buf() ~= self._buffers.list then
    vim.api.nvim_win_set_cursor(self.list, {1, 0})
    if vim.api.nvim_win_is_valid(self._sign) then
      vim.api.nvim_win_set_cursor(self._sign, {1, 0})
    end
  end

  source:highlight(self._buffers.list, items)
  source:highlight_sign(self._buffers.sign, items)
  self:redraw_selections(items)
end

function WindowGroup._redraw_input(self, input_lines, items, filters, opts)
  local height = #filters

  if vim.api.nvim_win_is_valid(self.input) then
    vim.api.nvim_win_set_height(self.input, height)
    vim.api.nvim_win_set_height(self._filter_info, height)
    vim.api.nvim_buf_set_lines(self._buffers.filter_info, 0, -1, false, vim.fn["repeat"]({""}, height))
    self._filter_height = height
  end

  local highlighter = self._info_hl_factory:reset(self._buffers.filter_info)
  for i, filter in ipairs(filters) do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(self._buffers.list, items, input_line, opts)
    end
    local filter_info = ("[%s]"):format(filter.name)
    highlighter:set_virtual_text(i - 1, {{filter_info, "ThettoFilterInfo"}})
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self._buffers.input, height - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self._buffers.input, height, -1, false, {})
  end
end

function WindowGroup._redraw_info(self, source, items, sorters, finished, result_count)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(sorters) do
    table.insert(sorter_names, sorter.name)
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local status = ""
  if not finished then
    status = "running"
  end

  local text = ("%s%s  [ %s / %s ]"):format(source.name, sorter_info, #items, result_count)
  local highlighter = self._info_hl_factory:reset(self._buffers.info)
  highlighter:set_virtual_text(0, {{text, "ThettoInfo"}, {"  " .. status, "Comment"}})
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function WindowGroup._set_left_padding(self)
  vim.wo[self.input].signcolumn = "yes:1"
  vim.wo[self._info].signcolumn = "yes:1"
end

function WindowGroup._close_group_name(self)
  return "theto_closed_" .. self._buffers.list
end

function WindowGroup._head_lines(items)
  local lines = {}
  for _, item in pairs(items) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

M._on_close = function(key, id)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  if not ui:has_window(id) then
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
  ui:on_move()
end

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
