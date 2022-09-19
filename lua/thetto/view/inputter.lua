local InputFilters = require("thetto.view.input_filters")
local Decorator = require("thetto.lib.decorator")
local windowlib = require("thetto.vendor.misclib.window")
local bufferlib = require("thetto.lib.buffer")
local vim = vim

local Inputter = {}
Inputter.__index = Inputter

local FILETYPE = "thetto-input"

function Inputter.new(source_name, filters, input_lines, width, height, row, column)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local name = ("thetto://%s/%s"):format(source_name, FILETYPE)
  bufferlib.delete_by_name(name)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.bo[bufnr].filetype = FILETYPE
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, input_lines)
  vim.bo[bufnr].bufhidden = "wipe"

  local input_height = #input_lines
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
    _decorator_factory = Decorator.factory("thetto-input-filter-info"),
    _source_name = source_name,
    _input_filters = InputFilters.new(source_name, filters),
  }
  return setmetatable(tbl, Inputter)
end

function Inputter.observable(self)
  local observable = require("thetto.vendor.misclib.observable").new(function(observer)
    vim.api.nvim_buf_attach(self._bufnr, false, {
      on_lines = function(_, _, _, row)
        observer:next(row)
      end,
      on_detach = function()
        observer:complete()
      end,
    })
  end)
  local get_lines = function()
    if not vim.api.nvim_buf_is_valid(self._bufnr) then
      return nil
    end
    return vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, true)
  end
  return observable, get_lines
end

function Inputter.redraw(self, input_lines, filters)
  local height = #filters

  if vim.api.nvim_win_is_valid(self._window) then
    vim.api.nvim_win_set_height(self._window, height)
  end

  local line_count_diff = height - #input_lines
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height - 1, -1, false, vim.fn["repeat"]({ "" }, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(self._bufnr, height, -1, false, {})
  end

  local decorator = self._decorator_factory:reset(self._bufnr)
  for i, filter in ipairs(filters) do
    local filter_info = ("[%s]"):format(filter.name)
    decorator:add_virtual_text(i - 1, 0, { { filter_info, "ThettoFilterInfo" } }, {
      virt_text_pos = "right_align",
    })
  end
end

function Inputter.recall_history(self, offset)
  local row = self:cursor()[1]
  local current_line = vim.api.nvim_buf_get_lines(self._bufnr, row - 1, row, false)[1] or ""
  local input_line = self._input_filters:recall_history(row, offset, current_line)
  vim.api.nvim_buf_set_lines(self._bufnr, row - 1, row, false, { input_line })
  vim.api.nvim_win_set_cursor(self._window, { row, #input_line })
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
  windowlib.safe_enter(self._window)
end

function Inputter.close(self)
  if self._closed then
    return
  end
  self._closed = true

  if vim.api.nvim_buf_is_valid(self._bufnr) then
    local input_lines = vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, false)
    self._input_filters:append(input_lines)
  end

  windowlib.safe_close(self._window)
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

function Inputter.height(self)
  return vim.api.nvim_win_get_height(self._window)
end

function Inputter.set_cursor(self, cursor)
  return vim.api.nvim_win_set_cursor(self._window, cursor)
end

function Inputter.start_insert(self, behavior)
  vim.cmd.startinsert()
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

function Inputter.append(self, appended)
  local row = self:cursor()[1]
  local current_line = vim.api.nvim_buf_get_lines(self._bufnr, row - 1, row, false)[1] or ""

  local new_line
  if not vim.endswith(current_line, " ") then
    local inputs = vim.split(current_line, "%s+")
    local input_tail = inputs[#inputs]
    new_line = current_line:sub(1, #current_line - #input_tail) .. appended
  else
    new_line = current_line .. appended
  end
  vim.api.nvim_buf_set_lines(self._bufnr, row - 1, row, false, { new_line })

  vim.api.nvim_win_set_cursor(self._window, { row, #new_line })
end

return Inputter
