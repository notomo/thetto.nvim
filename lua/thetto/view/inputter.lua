local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local highlights = require("thetto/lib/highlight")

local M = {}

local Inputter = {}
Inputter.__index = Inputter
M.Inputter = Inputter

local FILETYPE = "thetto-input"

function Inputter.new(collector, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    vim.api.nvim_buf_set_name(b, ("thetto://%s/%s"):format(collector.source.name, FILETYPE))
    vim.bo[b].filetype = FILETYPE
    vim.api.nvim_buf_set_lines(b, 0, -1, false, collector.input_lines)
    collector:attach(b)
    vim.api.nvim_buf_attach(b, false, {
      on_lines = function()
        return collector:update_with_debounce()
      end,
      on_detach = function()
        return collector:discard()
      end,
    })
  end)

  local input_width = math.floor(width * 0.75)
  local input_height = #collector.input_lines
  local window = vim.api.nvim_open_win(bufnr, false, {
    width = input_width,
    height = input_height,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[window].winhighlight = "Normal:ThettoInput,SignColumn:ThettoInput,CursorLine:ThettoInput"

  local filter_info_bufnr = bufferlib.scratch()
  local filter_info_window = vim.api.nvim_open_win(filter_info_bufnr, false, {
    width = width - input_width,
    height = input_height,
    relative = "editor",
    row = row + height + 1,
    col = column + input_width,
    external = false,
    style = "minimal",
  })
  local on_filter_info_enter = ("autocmd WinEnter <buffer=%s> lua require('thetto/lib/window').enter(%s)"):format(filter_info_bufnr, window)
  vim.cmd(on_filter_info_enter)

  local tbl = {
    bufnr = bufnr,
    window = window,
    _filter_info_bufnr = filter_info_bufnr,
    _filter_info_window = filter_info_window,
    _filter_info_hl_factory = highlights.new_factory("thetto-input-filter-info"),
    height = input_height,
  }
  local self = setmetatable(tbl, Inputter)
  self:_set_left_padding()
  return self
end

function Inputter.redraw(self, input_lines, filters)
  local height = #filters

  if vim.api.nvim_win_is_valid(self.window) then
    vim.api.nvim_win_set_height(self.window, height)
    vim.api.nvim_win_set_height(self._filter_info_window, height)
    vim.api.nvim_buf_set_lines(self._filter_info_bufnr, 0, -1, false, vim.fn["repeat"]({""}, height))
    self.height = height
  end

  local highlighter = self._filter_info_hl_factory:reset(self._filter_info_bufnr)
  for i, filter in ipairs(filters) do
    local filter_info = ("[%s]"):format(filter.name)
    highlighter:set_virtual_text(i - 1, {{filter_info, "ThettoFilterInfo"}})
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self.bufnr, height - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self.bufnr, height, -1, false, {})
  end
end

function Inputter.move_to(self, left_column)
  local input_config = vim.api.nvim_win_get_config(self.window)
  local filter_info_config = vim.api.nvim_win_get_config(self._filter_info_window)
  vim.api.nvim_win_set_config(self.window, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
  vim.api.nvim_win_set_config(self._filter_info_window, {
    relative = "editor",
    col = left_column + input_config.width,
    row = filter_info_config.row,
  })
  self:_set_left_padding()
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function Inputter._set_left_padding(self)
  vim.wo[self.window].signcolumn = "yes:1"
end

function Inputter.enter(self)
  windowlib.enter(self.window)
end

function Inputter.close(self)
  windowlib.close(self.window)
  windowlib.close(self._filter_info_window)
end

function Inputter.is_valid(self)
  return vim.api.nvim_win_is_valid(self.window) and vim.api.nvim_buf_is_valid(self.bufnr) and vim.api.nvim_win_is_valid(self._filter_info_window) and vim.api.nvim_buf_is_valid(self._filter_info_bufnr)
end

function Inputter.is_active(self)
  return vim.api.nvim_get_current_win() == self.window
end

return M
