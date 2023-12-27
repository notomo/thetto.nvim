--- @class ThettoUiSidecar
--- @field _closed boolean
local M = {}
M.__index = M

function M.open(ctx_key, closer, layout)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/sidecar"):format(ctx_key))

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
    _closed = false,
  }, M)
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
