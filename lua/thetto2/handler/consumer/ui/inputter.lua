local M = {}
M.__index = M

function M.open(closer, layout, raw_input_filters, on_change)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, _)
      on_change(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return require("thetto2.core.pipeline_context").new()
        end
        local inputs = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        return require("thetto2.core.pipeline_context").new(inputs)
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

  closer:setup_autocmd(window_id)

  local tbl = {
    _bufnr = bufnr,
    _window_id = window_id,
    _closed = false,
  }
  return setmetatable(tbl, M)
end

function M.enter(self)
  require("thetto2.vendor.misclib.window").safe_enter(self._window_id)
  vim.cmd.startinsert()
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true
  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
