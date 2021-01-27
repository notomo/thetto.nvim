local bufferlib = require("thetto/lib/buffer")
local highlights = require("thetto/lib/highlight")
local repository = require("thetto/core/repository")

local M = {}

local StatusLine = {}
StatusLine.__index = StatusLine
M.StatusLine = StatusLine

function StatusLine.new(source_name, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    vim.bo[b].modifiable = false
  end)

  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[window].winhighlight = "Normal:ThettoInfo,SignColumn:ThettoInfo,CursorLine:ThettoInfo"
  local on_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/view/status_line')._on_enter('%s', 'input')"):format(bufnr, source_name)
  vim.cmd(on_info_enter)

  local tbl = {
    bufnr = bufnr,
    window = window,
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

  local text = ("%s%s  [ %s / %s ]"):format(source.name, sorter_info, #items, result_count)
  local highlighter = self._info_hl_factory:reset(self.bufnr)
  highlighter:set_virtual_text(0, {{text, "ThettoInfo"}, {"  " .. status, "Comment"}})
end

function StatusLine.move_to(self, left_column)
  local config = vim.api.nvim_win_get_config(self.window)
  vim.api.nvim_win_set_config(self.window, {
    relative = "editor",
    col = left_column,
    row = config.row,
  })
end

function StatusLine.set_left_padding(self)
  vim.wo[self.window].signcolumn = "yes:1"
end

M._on_enter = function(key, to)
  local ui = repository.get(key).ui
  if ui == nil then
    return
  end
  ui:enter(to)
end

return M
