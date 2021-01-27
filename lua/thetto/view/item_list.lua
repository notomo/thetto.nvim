local bufferlib = require("thetto/lib/buffer")
local highlights = require("thetto/lib/highlight")

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

  local tbl = {
    bufnr = bufnr,
    window = window,
    _sign_bufnr = sign_bufnr,
    _sign_window = sign_window,
    _selection_hl_factory = highlights.new_factory("thetto-selection-highlight"),
  }
  return setmetatable(tbl, ItemList)
end

function ItemList.redraw(self, items, source)
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

return M
