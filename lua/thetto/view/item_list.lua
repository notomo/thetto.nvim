local Context = require("thetto.core.context").Context
local windowlib = require("thetto.lib.window")
local bufferlib = require("thetto.lib.buffer")
local cursorlib = require("thetto.lib.cursor")
local modelib = require("thetto.lib.mode")
local highlightlib = require("thetto.lib.highlight")
local vim = vim

local M = {}

local ItemList = {}
ItemList.__index = ItemList
M.ItemList = ItemList

local FILETYPE = "thetto"

function ItemList.new(source_name, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    local name = ("thetto://%s/%s"):format(source_name, FILETYPE)
    bufferlib.delete_by_name(name)
    vim.api.nvim_buf_set_name(b, name)
    vim.bo[b].filetype = FILETYPE
  end)

  local border_char = "―"
  if vim.o.ambiwidth == "double" then
    border_char = "-"
  end
  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - 2, -- NOTICE: calc border width
    height = height - 1,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
    border = {
      { " ", "NormalFloat" },
      { border_char, M._ThettoAboveBorder() },
      { " ", "NormalFloat" },
      { " ", "NormalFloat" },
      { "", "NormalFloat" },
      { "", "NormalFloat" },
      { " ", "NormalFloat" },
      { " ", "NormalFloat" },
    },
  })

  local group_name = "theto_closed_" .. bufnr
  vim.cmd(("augroup %s"):format(group_name))
  local on_win_closed = (
    "autocmd %s WinClosed * lua require('thetto.view.item_list')._on_close('%s', tonumber(vim.fn.expand('<afile>')))"
  ):format(group_name, source_name)
  vim.cmd(on_win_closed)
  vim.cmd("augroup END")

  vim.cmd(("autocmd BufReadCmd <buffer=%s> lua require('thetto.command').reload(%s)"):format(bufnr, bufnr))

  local tbl = { _bufnr = bufnr, _window = window }
  return setmetatable(tbl, ItemList)
end

function ItemList.redraw(self, items)
  local lines = vim.tbl_map(function(item)
    return item.desc or item.value
  end, items)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
  vim.bo[self._bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self._window) and vim.api.nvim_get_current_buf() ~= self._bufnr then
    vim.api.nvim_win_set_cursor(self._window, { 1, 0 })
  end
end

function ItemList.highlight(self, first_line, raw_items, source, input_lines, filters, filter_ctx)
  source:highlight(self._bufnr, first_line, raw_items)
  source:highlight_sign(self._bufnr, first_line, raw_items)

  local highligher = source.highlights:create(self._bufnr)
  highligher:filter("ThettoSelected", first_line, raw_items, function(item)
    return item.selected
  end)

  filters:highlight(filter_ctx, self._bufnr, first_line, raw_items, input_lines)
end

function ItemList.redraw_selections(self, s, e)
  vim.api.nvim__buf_redraw_range(self._bufnr, s, e)
end

function ItemList.move_to(self, left_column)
  local list_config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
end

function ItemList.is_valid(self)
  return vim.api.nvim_win_is_valid(self._window) and vim.api.nvim_buf_is_valid(self._bufnr)
end

function ItemList.is_active(self)
  return vim.api.nvim_get_current_win() == self._window
end

function ItemList.enable_on_moved(self, source_name)
  local on_moved = ("autocmd CursorMoved <buffer=%s> lua require('thetto.view.item_list')._on_moved('%s')"):format(
    self._bufnr,
    source_name
  )
  vim.cmd(on_moved)

  local on_moved_i = ("autocmd CursorMovedI <buffer=%s> stopinsert"):format(self._bufnr)
  vim.cmd(on_moved_i)
end

function ItemList.set_row(self, row)
  cursorlib.set_row(row, self._window, self._bufnr)
end

function ItemList.enter(self)
  windowlib.enter(self._window)
end

function ItemList.close(self)
  if self._closed then
    return
  end
  self._closed = true

  vim.cmd("autocmd! " .. "theto_closed_" .. self._bufnr)
  windowlib.close(self._window)
end

function ItemList.position(self)
  local config = vim.api.nvim_win_get_config(self._window)
  return { height = config.height + 1, row = config.row }
end

function ItemList.cursor(self)
  return vim.api.nvim_win_get_cursor(self._window)
end

function ItemList.has(self, id)
  return self._window == id
end

function M._on_moved(key)
  if modelib.is_visual() then
    return
  end
  local ctx = Context.get(key)
  if not ctx then
    return
  end
  ctx.ui:on_move()
end

function M._on_close(key, id)
  local ctx = Context.get(key)
  if not ctx then
    return
  end
  if not ctx.ui:has_window(id) then
    return
  end
  ctx.ui:close()
end

M._ThettoAboveBorder = highlightlib.Ensured.new("ThettoAboveBorder", function(hl_group)
  return highlightlib.default(hl_group, {
    ctermbg = { "NormalFloat", 235 },
    guibg = { "NormalFloat", "#213243" },
    ctermfg = { "Comment", 103 },
    guifg = { "Comment", "#8d9eb2" },
  })
end)

return M
