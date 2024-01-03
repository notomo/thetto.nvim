--- @class ThettoUiSidecar
--- @field _closed boolean
local M = {}
M.__index = M

function M.open(ctx_key, has_sidecar, layout)
  if not has_sidecar then
    return setmetatable({
      _ctx_key = ctx_key,
      _closed = true,
    }, M)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"

  local window_id = vim.api.nvim_open_win(bufnr, false, {
    width = layout.width,
    height = layout.height,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    focusable = false,
    external = false,
    style = "minimal",
    border = {
      { " ", "ThettoInput" },
      { layout.border_char, "ThettoAboveBorder" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
      { "", "ThettoInput" },
      { "", "ThettoInput" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
    },
  })

  return setmetatable({
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _layout = layout,
    _decorator_factory = require("thetto2.lib.decorator").factory("thetto-preview"),
    _closed = false,
  }, M)
end

function M.redraw(self, preview)
  local bufnr, callback =
    require("thetto2.handler.consumer.ui.preview").new(preview, self._layout.width, self._layout.height)
  if not bufnr then
    return
  end

  vim.api.nvim_win_set_buf(self._window_id, bufnr)

  local title = preview.title or ""
  if title ~= "" then
    title = " " .. title .. " "
  end
  vim.api.nvim_win_set_config(self._window_id, {
    title = { { title, "Comment" } },
    title_pos = "center",
  })

  callback(self._decorator_factory, self._window_id)
end

function M.enabled(self)
  return not self._closed
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
