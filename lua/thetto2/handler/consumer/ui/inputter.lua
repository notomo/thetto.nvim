local M = {}
M.__index = M

function M.open(setup_close_autocmd, layout, raw_input_filters, on_change)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, row)
      on_change(row, function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return nil
        end
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
      end)
    end,
  })

  local input_height = math.max(#raw_input_filters, 1)
  local window_id = vim.api.nvim_open_win(bufnr, false, {
    width = layout.width - 2,
    height = input_height,
    relative = "editor",
    row = layout.row + layout.height + 1,
    col = layout.column,
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

  setup_close_autocmd(window_id)

  local tbl = {
    _bufnr = bufnr,
    _window_id = window_id,
    _closed = false,
  }
  return setmetatable(tbl, M)
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true
  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
