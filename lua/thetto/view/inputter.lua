local windowlib = require("thetto/lib/window")
local bufferlib = require("thetto/lib/buffer")
local highlights = require("thetto/lib/highlight")
local vim = vim

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

  local input_height = #collector.input_lines
  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width,
    height = input_height,
    relative = "editor",
    row = row + height + 1,
    col = column,
    external = false,
    style = "minimal",
  })
  vim.wo[window].winhighlight = "Normal:ThettoInput,SignColumn:ThettoInput,CursorLine:ThettoInput"

  local tbl = {
    _bufnr = bufnr,
    _window = window,
    _filter_info_hl_factory = highlights.new_factory("thetto-input-filter-info"),
    height = input_height,
  }
  local self = setmetatable(tbl, Inputter)
  self:_set_left_padding()
  return self
end

function Inputter.redraw(self, input_lines, filters)
  local height = #filters

  if vim.api.nvim_win_is_valid(self._window) then
    vim.api.nvim_win_set_height(self._window, height)
    self.height = height
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height - 1, -1, false, vim.fn["repeat"]({""}, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height, -1, false, {})
  end

  local ns = vim.api.nvim_create_namespace("thetto-input-filter-info")
  vim.api.nvim_buf_clear_namespace(self._bufnr, ns, 0, -1)
  for i, filter in ipairs(filters) do
    local filter_info = ("[%s]"):format(filter.name)
    local column = vim.api.nvim_win_get_width(self._window) - #filter_info
    local space = (" "):rep(column - 3)
    vim.api.nvim_buf_set_extmark(self._bufnr, ns, i - 1, 0, {
      virt_text_pos = "overlay",
      virt_text_hide = false,
      hl_mode = "blend",
      virt_text = {{space, "ThettoBlend"}, {filter_info, "ThettoFilterInfo"}},
    })
  end
end

function Inputter.move_to(self, left_column)
  local input_config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = input_config.row,
  })
  self:_set_left_padding()
end

-- NOTE: nvim_win_set_config resets `signcolumn` if `style` is "minimal".
function Inputter._set_left_padding(self)
  vim.wo[self._window].signcolumn = "yes:1"
end

function Inputter.enter(self)
  windowlib.enter(self._window)
end

function Inputter.close(self)
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
