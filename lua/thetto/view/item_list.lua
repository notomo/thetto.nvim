local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local cursorlib = require("thetto/lib/cursor")
local highlights = require("thetto/lib/highlight")
local repository = require("thetto/core/repository")

local M = {}

local ItemList = {}
ItemList.__index = ItemList
M.ItemList = ItemList

local FILETYPE = "thetto"
local SIGN_WIDTH = 4

function ItemList.new(source_name, display_limit, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    vim.api.nvim_buf_set_name(b, ("thetto://%s/%s"):format(source_name, FILETYPE))
    vim.bo[b].filetype = FILETYPE
  end)

  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - SIGN_WIDTH,
    height = height,
    relative = "editor",
    row = row,
    col = column + SIGN_WIDTH,
    external = false,
    style = "minimal",
  })
  vim.wo[window].scrollbind = true

  local sign_bufnr = bufferlib.scratch(function(b)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, vim.fn["repeat"]({""}, display_limit))
    vim.bo[b].modifiable = false
  end)

  local sign_window = vim.api.nvim_open_win(sign_bufnr, false, {
    width = SIGN_WIDTH,
    height = height,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[sign_window].winhighlight = "Normal:ThettoColorLabelBackground"
  vim.wo[sign_window].scrollbind = true

  local on_sign_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/lib/window').enter(%s)"):format(sign_bufnr, window)
  vim.cmd(on_sign_enter)

  local group_name = "theto_closed_" .. bufnr
  vim.cmd(("augroup %s"):format(group_name))
  local on_win_closed = ("autocmd %s WinClosed * lua require('thetto/view/item_list')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"):format(group_name, source_name)
  vim.cmd(on_win_closed)
  vim.cmd("augroup END")

  local tbl = {
    bufnr = bufnr,
    window = window,
    _sign_bufnr = sign_bufnr,
    _sign_window = sign_window,
    _selection_hl_factory = highlights.new_factory("thetto-selection-highlight"),
  }
  return setmetatable(tbl, ItemList)
end

function ItemList.redraw(self, items, source, input_lines, filters, opts)
  local lines = vim.tbl_map(function(item)
    return item.desc or item.value
  end, items)

  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.bo[self.bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self.window) and vim.api.nvim_get_current_buf() ~= self.bufnr then
    vim.api.nvim_win_set_cursor(self.window, {1, 0})
    if vim.api.nvim_win_is_valid(self._sign_window) then
      vim.api.nvim_win_set_cursor(self._sign_window, {1, 0})
    end
  end

  source:highlight(self.bufnr, items)
  source:highlight_sign(self._sign_bufnr, items)
  self:redraw_selections(items)

  for i, filter in ipairs(filters) do
    local input_line = input_lines[i] or ""
    if filter.highlight ~= nil and input_line ~= "" then
      filter:highlight(self.bufnr, items, input_line, opts)
    end
  end
end

function ItemList.redraw_selections(self, items)
  local highligher = self._selection_hl_factory:reset(self.bufnr)
  highligher:filter("ThettoSelected", items, function(item)
    return item.selected
  end)
end

function ItemList.move_to(self, left_column)
  local list_config = vim.api.nvim_win_get_config(self.window)
  local sign_config = vim.api.nvim_win_get_config(self._sign_window)
  vim.api.nvim_win_set_config(self.window, {
    relative = "editor",
    col = left_column + sign_config.width,
    row = list_config.row,
  })
  vim.api.nvim_win_set_config(self._sign_window, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
end

function ItemList.is_valid(self)
  return vim.api.nvim_win_is_valid(self.window) and vim.api.nvim_buf_is_valid(self.bufnr)
end

function ItemList.enable_on_moved(self, source_name)
  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto/view/item_list')._on_moved('%s')"):format(self.bufnr, source_name)
  vim.cmd(on_moved)

  local on_moved_i = ("autocmd CursorMovedI <buffer=%s> stopinsert"):format(self.bufnr)
  vim.cmd(on_moved_i)
end

function ItemList.set_row(self, row)
  cursorlib.set_row(row, self.window, self.bufnr)
end

function ItemList.enter(self)
  windowlib.enter(self.window)
end

M._on_moved = function(key)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:on_move()
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

return M
