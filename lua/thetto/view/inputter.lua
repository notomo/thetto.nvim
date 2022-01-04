local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local windowlib = require("thetto.lib.window")
local bufferlib = require("thetto.lib.buffer")
local vim = vim

local M = {}

local Inputter = {}
Inputter.__index = Inputter
M.Inputter = Inputter

local FILETYPE = "thetto-input"

function Inputter.new(collector, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    local name = ("thetto://%s/%s"):format(collector.source.name, FILETYPE)
    bufferlib.delete_by_name(name)
    vim.api.nvim_buf_set_name(b, name)
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

  local input_height = #collector.input_lines
  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - 2,
    height = input_height,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
    border = {
      { "", "ThettoInput" },
      { "", "ThettoInput" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
      { "", "ThettoInput" },
      { "", "ThettoInput" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
    },
  })
  vim.wo[window].winhighlight = "Normal:ThettoInput,CursorLine:ThettoInput"

  local tbl = {
    _bufnr = bufnr,
    _window = window,
    height = input_height,
    _hl_factory = HighlighterFactory.new("thetto-input-filter-info"),
  }
  return setmetatable(tbl, Inputter)
end

function Inputter.redraw(self, input_lines, filters)
  local height = #filters

  if vim.api.nvim_win_is_valid(self._window) then
    vim.api.nvim_win_set_height(self._window, height)
    self.height = height
  end

  local highlighter = self._hl_factory:reset(self._bufnr)
  for i, filter in ipairs(filters) do
    local filter_info = ("[%s]"):format(filter.name)
    highlighter:set_virtual_text(i - 1, { { filter_info, "ThettoFilterInfo" } }, {
      virt_text_pos = "right_align",
    })
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height - 1, -1, false, vim.fn["repeat"]({ "" }, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height, -1, false, {})
  end
end

function Inputter.move_to(self, left_column)
  local input_config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
end

function Inputter.enter(self)
  windowlib.enter(self._window)
end

function Inputter.close(self)
  if self._closed then
    return
  end
  self._closed = true

  windowlib.close(self._window)
end

function Inputter.is_valid(self)
  return vim.api.nvim_win_is_valid(self._window) and vim.api.nvim_buf_is_valid(self._bufnr)
end

function Inputter.is_active(self)
  return vim.api.nvim_get_current_win() == self._window
end

function Inputter.cursor(self)
  return vim.api.nvim_win_get_cursor(self._window)
end

function Inputter.set_cursor(self, cursor)
  return vim.api.nvim_win_set_cursor(self._window, cursor)
end

function Inputter.start_insert(self, behavior)
  vim.cmd("startinsert")
  if behavior == "a" then
    local max_col = vim.fn.col("$")
    local cursor = self:cursor()
    if cursor[2] ~= max_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(self._window, cursor)
    end
  end
end

function Inputter.has(self, id)
  return self._window == id
end

return M
