local Context = require("thetto.core.context").Context
local windowlib = require("thetto.lib.window")
local bufferlib = require("thetto.lib.buffer")
local highlights = require("thetto.lib.highlight")
local vim = vim

local M = {}

local StatusLine = {}
StatusLine.__index = StatusLine
M.StatusLine = StatusLine

function StatusLine.new(source_name, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    vim.bo[b].modifiable = false
  end)

  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - 2,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
    border = {
      {"", "ThettoInfo"},
      {"", "ThettoInfo"},
      {" ", "ThettoInfo"},
      {" ", "ThettoInfo"},
      {"", "ThettoInfo"},
      {"", "ThettoInfo"},
      {" ", "ThettoInfo"},
      {" ", "ThettoInfo"},
    },
  })
  vim.wo[window].winhighlight = "Normal:ThettoInfo,CursorLine:ThettoInfo"
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto.view.status_line')._on_enter('%s')"):format(bufnr, source_name)
  vim.cmd(on_info_enter)

  local tbl = {
    _bufnr = bufnr,
    _window = window,
    _info_hl_factory = highlights.new_factory("thetto-info-text"),
  }
  return setmetatable(tbl, StatusLine)
end

function StatusLine.redraw(self, source, items, sorters, finished, result_count)
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

  local text = ("%s%s [ %s / %s ]"):format(source.name, sorter_info, #items, result_count)
  local highlighter = self._info_hl_factory:reset(self._bufnr)
  highlighter:set_virtual_text(0, {{text, "ThettoInfo"}, {" "}, {status, "Comment"}}, {
    virt_text_pos = "overlay",
  })
end

function StatusLine.move_to(self, left_column)
  local config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = config.row,
  })
end

function StatusLine.close(self)
  if self._closed then
    return
  end
  self._closed = true

  windowlib.close(self._window)
end

function StatusLine.has(self, id)
  return self._window == id
end

function M._on_enter(key)
  local ctx = Context.get(key)
  if not ctx then
    return
  end
  ctx.ui:into_inputter()
end

return M
