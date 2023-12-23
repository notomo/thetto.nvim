--- @class ThettoUiItemList
--- @field _closed boolean
local M = {}
M.__index = M

local _selfs = {}
local _resume_states = {}
local _states = {}

function M.open(ctx_key, cwd, closer, layout)
  local resume_state = _resume_states[ctx_key] or {
    has_forcus = false,
    cursor = { 1, 0 },
  }
  _resume_states[ctx_key] = resume_state

  local state = _states[ctx_key]
    or {
      items = {},
      status = "running",
      source_name = nil,
      page = 0,
      limit = 100,
      start_index = 1,
      end_index = 1,
      all_items_count = 0,
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

  local window_id = vim.api.nvim_open_win(bufnr, resume_state.has_forcus, {
    width = layout.width - 2, -- NOTICE: calc border width
    height = layout.height - 1,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    footer = M._footer(state, resume_state.cursor[1]),
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

  vim.api.nvim_win_set_cursor(window_id, resume_state.cursor)

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
      _resume_states[ctx_key] = nil
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

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    buffer = bufnr,
    callback = function()
      self:redraw_footer(nil, nil)
    end,
  })

  return self
end

function M.redraw_list(self, items, all_items_count)
  local state = vim.tbl_extend("keep", {
    items = items,
    all_items_count = all_items_count,
  }, _states[self._ctx_key])
  _states[self._ctx_key] = state

  local items_count = #state.items
  local page = math.min(state.page, math.floor(items_count / state.limit))

  local start_index = 1 + state.limit * page
  start_index = math.min(items_count, start_index)

  local end_index = state.limit * (page + 1)
  end_index = math.min(items_count, end_index)

  state = vim.tbl_extend("keep", {
    start_index = start_index,
    end_index = end_index,
  }, _states[self._ctx_key])
  _states[self._ctx_key] = state

  local index = 1
  local paged_items = {}
  for i = start_index, end_index, 1 do
    paged_items[index] = items[i]
    index = index + 1
  end

  local lines = vim.tbl_map(function(item)
    return item.desc or item.value
  end, paged_items)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
  vim.bo[self._bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self._window_id) and vim.api.nvim_get_current_buf() ~= self._bufnr then
    vim.api.nvim_win_set_cursor(self._window_id, { 1, 0 })
  end

  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  vim.api.nvim_win_set_config(self._window_id, {
    footer = M._footer(state, row),
  })
end

function M.redraw_footer(self, source_name, status)
  local state = vim.tbl_extend("keep", {
    source_name = source_name,
    status = status,
  }, _states[self._ctx_key])
  _states[self._ctx_key] = state

  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  vim.api.nvim_win_set_config(self._window_id, {
    footer = M._footer(state, row),
  })
end

function M._footer(state, row)
  local line = ("%s [ %s - %s / %s , %s ] "):format(
    state.source_name,
    state.start_index,
    state.end_index,
    state.all_items_count,
    state.start_index + row - 1
  )
  return { { line, "StatusLine" }, { state.status, "Comment" } }
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

  local resume_state = {
    has_forcus = vim.api.nvim_get_current_win() == self._window_id,
    cursor = vim.api.nvim_win_get_cursor(self._window_id),
  }
  _resume_states[self._ctx_key] = resume_state

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
  vim.api.nvim_set_decoration_provider(ns, {})
end

return M
