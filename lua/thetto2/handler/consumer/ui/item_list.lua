local M = {}
M.__index = M

function M.open(closer, layout)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2"

  local border_char = "─"
  if vim.o.ambiwidth == "double" then
    border_char = "-"
  end

  local window_id = vim.api.nvim_open_win(bufnr, false, {
    width = layout.width - 2, -- NOTICE: calc border width
    height = layout.height - 1,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    footer = { { "TODO", "StatusLine" } },
    footer_pos = "left",
    border = {
      { " ", "NormalFloat" },
      { border_char, "ThettoAboveBorder" },
      { " ", "NormalFloat" },
      { " ", "NormalFloat" },
      { " ", "StatusLine" },
      { " ", "StatusLine" },
      { " ", "StatusLine" },
      { " ", "NormalFloat" },
    },
  })

  closer:setup_autocmd(window_id)

  return setmetatable({
    _bufnr = bufnr,
    _window_id = window_id,
  }, M)
end

function M.redraw(self, items)
  local lines = vim.tbl_map(function(item)
    return item.desc or item.value
  end, items)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
  vim.bo[self._bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self._window_id) and vim.api.nvim_get_current_buf() ~= self._bufnr then
    vim.api.nvim_win_set_cursor(self._window_id, { 1, 0 })
  end
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true
  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
