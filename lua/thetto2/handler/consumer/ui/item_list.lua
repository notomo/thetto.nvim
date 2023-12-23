--- @class ThettoUiItemList
--- @field _closed boolean
local M = {}
M.__index = M

local _selfs = {}
local _states = {}

function M.open(ctx_key, cwd, closer, layout)
  local state = _states[ctx_key]
    or {
      has_forcus = false,
      cursor = { 1, 0 },
      status = "running",
      source_name = nil,
    }
  _states[ctx_key] = state

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/list"):format(ctx_key))

  local border_char = "─"
  if vim.o.ambiwidth == "double" then
    border_char = "-"
  end

  local window_id = vim.api.nvim_open_win(bufnr, state.has_forcus, {
    width = layout.width - 2, -- NOTICE: calc border width
    height = layout.height - 1,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    footer = M._footer(state),
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

  vim.api.nvim_win_set_cursor(window_id, state.cursor)

  closer:setup_autocmd(window_id)

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      require("thetto2").reload(bufnr)
    end,
  })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "thetto_ctx_deleted_" .. ctx_key },
    callback = function()
      _states[ctx_key] = nil
    end,
    once = true,
  })

  local self = setmetatable({
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _closed = false,
  }, M)
  _selfs[bufnr] = self
  return self
end

function M.redraw_list(self, items)
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

function M.redraw_footer(self, source_name, status)
  local state = vim.tbl_extend("keep", {
    source_name = source_name,
    status = status,
  }, _states[self._ctx_key])
  _states[self._ctx_key] = state

  vim.api.nvim_win_set_config(self._window_id, {
    footer = M._footer(state),
  })
end

function M._footer(state)
  local line = ("%s %s"):format(state.source_name, state.status)
  return { { line, "StatusLine" } }
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

  local state = {
    has_forcus = vim.api.nvim_get_current_win() == self._window_id,
    cursor = vim.api.nvim_win_get_cursor(self._window_id),
  }
  _states[self._ctx_key] = state

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
  vim.api.nvim_set_decoration_provider(ns, {})
end

return M
