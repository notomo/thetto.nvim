local highlights = require("thetto/lib/highlight")
local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local filelib = require("thetto/lib/file")
local repository = require("thetto/core/repository")

local M = {}

local UI = {}
UI.__index = UI

local input_filetype = "thetto-input"
local sign_filetype = "thetto-sign"
local list_filetype = "thetto"
local info_filetype = "thetto-info"
local filter_info_filetype = "thetto-filter-info"

function UI.open(self)
  local source = self.collector.source
  local opts = self.collector.opts

  local ids = vim.api.nvim_tabpage_list_wins(0)
  for _, id in ipairs(ids) do
    local bufnr = vim.fn.winbufnr(id)
    if bufnr == -1 then
      goto continue
    end
    local ctx, _ = repository.get_from_path(bufnr)
    if ctx ~= nil then
      ctx.ui:close()
    end
    ::continue::
  end

  self.input_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, input_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", input_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, #source.filters))
  end)
  vim.api.nvim_buf_attach(self.input_bufnr, false, {
    on_lines = function()
      local input_lines = vim.api.nvim_buf_get_lines(self.input_bufnr, 0, -1, true)
      return self.notifier:send("update_input", input_lines)
    end,
    on_detach = function()
      return self.notifier:send("finish")
    end,
  })

  self.sign_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, sign_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", sign_filetype)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn["repeat"]({""}, opts.display_limit))
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  self.list_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, list_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", list_filetype)
  end)

  self.info_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, info_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", info_filetype)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end)

  self.filter_info_bufnr = bufferlib.force_create(("thetto://%s/%s"):format(source.name, filter_info_filetype), function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "filetype", filter_info_filetype)
  end)

  self.notifier:on("update_items", function(input_lines)
    local err = self:redraw(input_lines)
    if err ~= nil then
      return err
    end
    M._changed_after(input_lines)
  end)

  self.notifier:on("update_selected", function()
    self:_update_selections_hl()
  end)

  self:_open_windows()
end

function UI._update_selections_hl(self)
  local highligher = self._selection_hl_factory:reset(self.list_bufnr)
  highligher:filter("ThettoSelected", self.collector.items, function(item)
    return item.selected
  end)
end

function UI._open_windows(self)
  local source = self.collector.source

  local sign_width = 4
  local height = math.floor(vim.o.lines * 0.5)
  local width = math.floor(vim.o.columns * 0.6)
  local row = (vim.o.lines - height) / 2
  local column = (vim.o.columns - width) / 2
  self.origin_window = vim.api.nvim_get_current_win()

  self.list_window = vim.api.nvim_open_win(self.list_bufnr, false, {
    width = width - sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column + sign_width,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(self.list_window, "scrollbind", true)

  self.sign_window = vim.api.nvim_open_win(self.sign_bufnr, false, {
    width = sign_width,
    height = height,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(self.sign_window, "winhighlight", "Normal:ThettoColorLabelBackground")
  vim.api.nvim_win_set_option(self.sign_window, "scrollbind", true)
  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._enter('list')"):format(self.sign_bufnr)
  vim.api.nvim_command(on_sign_enter)

  local input_width = math.floor(width * 0.75)
  self.input_window = vim.api.nvim_open_win(self.input_bufnr, false, {
    width = input_width,
    height = #self.collector.filters,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(self.input_window, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(self.input_window, "winhighlight", "SignColumn:NormalFloat")

  self.info_window = vim.api.nvim_open_win(self.info_bufnr, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(self.info_window, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(self.info_window, "winhighlight", "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo")
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('input')"):format(self.info_bufnr)
  vim.api.nvim_command(on_info_enter)

  self.filter_info_window = vim.api.nvim_open_win(self.filter_info_bufnr, false, {
    width = width - input_width,
    height = #self.collector.filters,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/ui')._on_enter('input')"):format(self.filter_info_bufnr)
  vim.api.nvim_command(on_filter_info_enter)

  local group_name = self:_close_group_name()
  vim.api.nvim_command(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/ui')._on_close(\"%s\", tonumber(vim.fn.expand('<afile>')))"):format(group_name, source.name)
  vim.api.nvim_command(on_win_closed)
  vim.api.nvim_command("augroup END")

  if self.active == "input" then
    vim.api.nvim_set_current_win(self.input_window)
  else
    vim.api.nvim_set_current_win(self.list_window)
  end
  if self.mode == "n" then
    vim.api.nvim_command("stopinsert")
  else
    vim.api.nvim_command("startinsert")
  end

  self.windows = {
    list = self.list_window,
    sign = self.sign_window,
    input = self.input_window,
    info = self.info_window,
    filter_info = self.filter_info_window,
  }

  local preview_width = math.floor((vim.o.columns - width) / 2) - 2
  local preview_column = width + column + 1
  self.preview_row = row
  self.preview_column = preview_column
  self.preview_width = preview_width
  self.preview_height = height + 1
end

function UI.resume(self)
  self:_open_windows()
end

function UI._close_group_name(self)
  return "theto_closed_" .. self.list_bufnr
end

function UI.redraw(self, input_lines)
  if not vim.api.nvim_buf_is_valid(self.list_bufnr) then
    return
  end

  local collector = self.collector
  local items = collector.items
  local opts = collector.opts
  local lines = self._head_lines(items, opts.display_limit)
  vim.api.nvim_buf_set_option(self.list_bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(self.list_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.list_bufnr, "modifiable", false)

  self:_redraw_info()

  if vim.api.nvim_win_is_valid(self.list_window) and vim.bo.filetype ~= list_filetype then
    vim.api.nvim_win_set_cursor(self.list_window, {1, 0})
    if vim.api.nvim_win_is_valid(self.sign_window) then
      vim.api.nvim_win_set_cursor(self.sign_window, {1, 0})
    end
  end

  local source = collector.source
  source:highlight(self.list_bufnr, items)
  source:highlight_sign(self.sign_bufnr, items)
  self:_update_selections_hl()

  local filters = collector.filters
  if vim.api.nvim_win_is_valid(self.input_window) then
    local input_height = #filters
    vim.api.nvim_win_set_height(self.input_window, input_height)
    vim.api.nvim_win_set_height(self.filter_info_window, input_height)
    vim.api.nvim_buf_set_lines(self.filter_info_bufnr, 0, -1, false, vim.fn["repeat"]({""}, input_height))
  end

  local ns = vim.api.nvim_create_namespace("thetto-input-filter-info")
  input_lines = input_lines or {}
  for i, filter in ipairs(filters) do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(self.list_bufnr, items, input_line, opts)
    end
    local filter_info = ("[%s]"):format(filter.name)
    vim.api.nvim_buf_set_virtual_text(self.filter_info_bufnr, ns, i - 1, {{filter_info, "Comment"}}, {})
  end

  local line_count_diff = #filters - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self.input_bufnr, #filters - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self.input_bufnr, #filters, -1, false, {})
  end
end

function UI._redraw_info(self)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(self.collector.sorters) do
    table.insert(sorter_names, sorter:get_name())
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local collector_status = ""
  if not self.collector:finished() then
    collector_status = "running"
  end

  local ns = vim.api.nvim_create_namespace("thetto-info-text")
  vim.api.nvim_buf_clear_namespace(self.info_bufnr, ns, 0, -1)
  local text = ("%s%s  [ %s / %s ]"):format(self.collector.source.name, sorter_info, vim.tbl_count(self.collector.items), #self.collector.all_items)
  vim.api.nvim_buf_set_virtual_text(self.info_bufnr, ns, 0, {
    {text, "ThettoInfo"},
    {"  " .. collector_status, "Comment"},
  }, {})
end

function UI.update_offset(self, offset)
  local row = self.row + offset
  local line_count = vim.api.nvim_buf_line_count(self.list_bufnr)
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
  local cursor = vim.api.nvim_win_get_cursor(self.input_window)
  return self.collector.filters[cursor[1]]
end

function UI.current_position_sorter(self)
  local cursor = vim.api.nvim_win_get_cursor(self.input_window)
  return self.collector.sorters[cursor[1]]
end

function UI.start_insert(self, behavior)
  vim.api.nvim_command("startinsert")
  if behavior == "a" then
    local max_col = vim.fn.col("$")
    local cursor = vim.api.nvim_win_get_cursor(self.input_window)
    if cursor[2] ~= max_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(self.input_window, cursor)
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
  if filetype == input_filetype or filetype == info_filetype then
    index = 1
  elseif vim.bo.filetype == list_filetype then
    index = vim.fn.line(".")
  else
    index = self.row
  end
  return {self.collector.items[index]}
end

function UI.open_preview(self, open_target)
  self:close_preview()

  local height = self.preview_height + #self.collector.filters
  local half_height = math.floor(height / 2)

  local top_row = 1
  local row = open_target.row
  if open_target.row ~= nil and open_target.row > half_height then
    top_row = open_target.row - half_height + 1
    row = half_height
  end

  local lines
  if open_target.bufnr ~= nil then
    local bufnr = open_target.bufnr
    lines = vim.api.nvim_buf_get_lines(bufnr, top_row - 1, top_row + height - 1, false)
  else
    lines = filelib.read_lines(open_target.path, top_row, top_row + height)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  self.preview_window = vim.api.nvim_open_win(bufnr, false, {
    width = self.preview_width,
    height = height,
    relative = "editor",
    row = self.preview_row,
    col = self.preview_column,
    focusable = false,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(self.preview_window, "scrollbind", false)

  if row ~= nil then
    local highlighter = self._preview_hl_factory:create(bufnr)
    local range = open_target.range or {s = {column = 0}, e = {column = -1}}
    highlighter:add("Search", row - 1, range.s.column, range.e.column)
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
end

function UI._head_lines(items)
  local lines = {}
  for _, item in pairs(items) do
    table.insert(lines, item.desc or item.value)
  end
  return lines
end

M.new = function(collector, notifier)
  local tbl = {collector = collector, notifier = notifier, windows = {}, row = 1}

  if collector.opts.insert then
    tbl.active = "input"
    tbl.mode = "i"
  else
    tbl.active = "list"
    tbl.mode = "n"
  end

  tbl._selection_hl_factory = highlights.new_factory("thetto-selection-highlight")
  tbl._preview_hl_factory = highlights.new_factory("thetto-preview")

  local ui = setmetatable(tbl, UI)
  return ui
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

-- for testing
M._changed_after = function(_)
end

return M
