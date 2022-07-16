local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local windowlib = require("thetto.vendor.misclib.window")
local vim = vim

local Sidecar = {}
Sidecar.__index = Sidecar

function Sidecar.new()
  local tbl = { _window = nil, _hl_factory = HighlighterFactory.new("thetto-preview") }
  return setmetatable(tbl, Sidecar)
end

function Sidecar.open(self, item, open_target, width, height, pos_row, left_column)
  local sidecar_width = math.ceil(vim.o.columns - left_column - width - 3 - 2)
  local bufnr, window_open_callback = require("thetto.view.open_target").new(open_target, sidecar_width, height)

  if not self:_opened() then
    self._window = vim.api.nvim_open_win(bufnr, false, {
      width = sidecar_width,
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

  window_open_callback(self._hl_factory, self._window)

  local index
  if item then
    index = item.index
  end
  self._index = index
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
