local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local windowlib = require("thetto.vendor.misclib.window")
local filelib = require("thetto.lib.file")
local vim = vim

local Sidecar = {}
Sidecar.__index = Sidecar

function Sidecar.new()
  local tbl = { _window = nil, _hl_factory = HighlighterFactory.new("thetto-preview") }
  return setmetatable(tbl, Sidecar)
end

function Sidecar.open(self, item, open_target, width, height, pos_row, left_column)
  if open_target.bufnr ~= nil and not vim.api.nvim_buf_is_valid(open_target.bufnr) then
    return
  end

  local half_height = math.floor(height / 2)

  local top_row = 1
  local row = open_target.row
  if open_target.row ~= nil and open_target.row > half_height then
    top_row = open_target.row - half_height + 1
    row = half_height
  end

  local lines
  if open_target.bufnr ~= nil then
    lines = vim.api.nvim_buf_get_lines(open_target.bufnr, top_row - 1, top_row + height - 1, false)
  elseif open_target.path ~= nil then
    lines = filelib.read_lines(open_target.path, top_row, top_row + height)
  elseif open_target.lines ~= nil then
    lines = open_target.lines
  else
    lines = {}
  end

  local bufnr
  if open_target.raw_bufnr then
    bufnr = open_target.raw_bufnr
  else
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].bufhidden = "wipe"
  end

  if not self:_opened() then
    self._window = vim.api.nvim_open_win(bufnr, false, {
      width = math.ceil(vim.o.columns - left_column - width - 3 - 2),
      height = height,
      relative = "editor",
      row = pos_row,
      col = left_column + width + 1,
      focusable = false,
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
  else
    vim.api.nvim_win_set_buf(self._window, bufnr)
  end

  local index
  if item then
    index = item.index
  end
  self._index = index

  if open_target.execute ~= nil then
    local origin = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(self._window)
    open_target.execute()
    vim.api.nvim_set_current_win(origin)
  end

  if row ~= nil then
    local highlighter = self._hl_factory:create(bufnr)
    local range = open_target.range or { s = { column = 0 }, e = { column = -1 } }
    highlighter:add_normal("ThettoPreview", row - 1, range.s.column, range.e.column)
    if vim.fn.getbufline(bufnr, row)[1] == "" then
      highlighter:set_virtual_text(row - 1, { { " ", "ThettoPreview" } }, { virt_text_pos = "overlay" })
    end
  end
end

function Sidecar.exists_same(self, item)
  if not self:_opened() then
    return false
  end
  return item ~= nil and item.index == self._index
end

function Sidecar.close(self)
  if not self._window then
    return
  end
  windowlib.safe_close(self._window)
end

function Sidecar._opened(self)
  return self._window ~= nil and vim.api.nvim_win_is_valid(self._window)
end

return Sidecar
