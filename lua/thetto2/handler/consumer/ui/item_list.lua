local M = {}
M.__index = M

local _selfs = {}

function M.open(ctx_key, cwd, closer, layout)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/list"):format(ctx_key))

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
    footer = { { "running", "StatusLine" } },
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

  vim.api.nvim_win_call(window_id, function()
    local ok, result = pcall(require("thetto2.lib.file").lcd, cwd)
    if not ok then
      vim.notify("[thetto] " .. result, vim.log.levels.WARN)
    end
  end)

  closer:setup_autocmd(window_id)

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      require("thetto2").reload(bufnr)
    end,
  })

  local self = setmetatable({
    _bufnr = bufnr,
    _window_id = window_id,
  }, M)
  _selfs[bufnr] = self
  return self
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

function M.redraw_status(self, message)
  vim.api.nvim_win_set_config(self._window_id, {
    footer = message,
  })
end

local ns = vim.api.nvim_create_namespace("thetto2-list-highlight")

function M._highlight_handler(_, _, bufnr, topline, botline_guess)
  local self = _selfs[bufnr]
  if not self then
    return false
  end
  self:highlight(topline, botline_guess)
  return false
end

function M.highlight(self)
  return nil
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true
  _selfs[self._bufnr] = nil
  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
  vim.api.nvim_set_decoration_provider(ns, {})
end

return M
