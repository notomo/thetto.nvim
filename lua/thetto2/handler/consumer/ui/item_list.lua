--- @class ThettoUiItemList
--- @field _closed boolean
--- @field _sidecar ThettoUiSidecar
local M = {}
M.__index = M

local _ns_name = "thetto2-list-highlight"
local _ns = vim.api.nvim_create_namespace(_ns_name)

local _selfs = {}
local _resume_states = {}
local _states = {}

--- @param sidecar ThettoUiSidecar
function M.open(ctx_key, cwd, closer, layout, sidecar, item_cursor_row)
  local resume_state = _resume_states[ctx_key] or {
    has_forcus = false,
    column = 0,
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
      selected_items = {},
    }
  _states[ctx_key] = state

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/list"):format(ctx_key))

  local window_id = vim.api.nvim_open_win(bufnr, resume_state.has_forcus, {
    width = layout.width,
    height = layout.height,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    footer = M._footer(state, item_cursor_row),
    footer_pos = "left",
    border = {
      { " ", "NormalFloat" },
      { layout.border_char, "ThettoAboveBorder" },
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
    _sidecar = sidecar,
    _decorator = require("thetto2.lib.decorator").factory(_ns_name):create(bufnr, true),
    _closed = false,
  }, M)
  _selfs[bufnr] = self

  self:redraw_list(state.items, state.all_items_count)
  vim.api.nvim_win_set_cursor(window_id, { item_cursor_row, resume_state.column })

  local on_cursor_moved = require("thetto2.lib.debounce").promise(100, function()
    self:redraw_footer(nil, nil)
    return self:_redraw_sidecar()
  end)
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    buffer = bufnr,
    callback = function()
      on_cursor_moved()
    end,
  })

  vim.api.nvim_set_decoration_provider(_ns, {})
  vim.api.nvim_set_decoration_provider(_ns, {
    on_win = function(_, _, self_bufnr, topline, botline_guess)
      local item_list = _selfs[self_bufnr]
      if not item_list then
        return false
      end

      item_list:highlight(topline, botline_guess)

      return false
    end,
  })

  return self
end

function M.redraw_list(self, items, all_items_count)
  local state = vim.tbl_extend("keep", {
    items = items,
    all_items_count = all_items_count,
  }, _states[self._ctx_key])

  local items_count = #state.items
  local page = math.min(state.page, math.floor(items_count / state.limit))

  local start_index = 1 + state.limit * page
  start_index = math.min(items_count, start_index)

  local end_index = state.limit * (page + 1)
  end_index = math.min(items_count, end_index)

  state = vim.tbl_extend("keep", {
    start_index = start_index,
    end_index = end_index,
  }, state)
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

  self:_redraw_sidecar()
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

function M.apply_item_cursor(self, item_cursor)
  local row, column = unpack(vim.api.nvim_win_get_cursor(self._window_id))
  row = math.max(1, row + item_cursor.row_offset)
  row = math.min(row, vim.api.nvim_buf_line_count(self._bufnr))
  vim.api.nvim_win_set_cursor(self._window_id, { row, column })
end

function M._footer(state, row)
  local line = ("%s [ %s - %s / %s , %s ] "):format(
    state.source_name,
    state.start_index,
    state.end_index,
    state.all_items_count,
    state.start_index + row - 1
  )
  return {
    { line, "StatusLine" },
    { state.status, "Comment" },
  }
end

function M.highlight(self, topline, botline_guess)
  local state = _states[self._ctx_key]
  local items = state.items

  local displayed_items = {}
  for i = topline + 1, botline_guess + 1, 1 do
    table.insert(displayed_items, items[i])
  end

  local selected_items = state.selected_items
  self._decorator:filter("Statement", topline, displayed_items, function(item)
    return selected_items[item.index] ~= nil
  end)
end

function M.enter(self)
  require("thetto2.vendor.misclib.window").safe_enter(self._window_id)
  vim.cmd.stopinsert()
end

function M.close(self, current_window_id)
  if self._closed then
    return 1
  end
  self._closed = true
  _selfs[self._bufnr] = nil

  local row, column = unpack(vim.api.nvim_win_get_cursor(self._window_id))
  local resume_state = {
    has_forcus = current_window_id == self._window_id,
    column = column,
  }
  _resume_states[self._ctx_key] = resume_state

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
  vim.api.nvim_set_decoration_provider(_ns, {})

  return row
end

function M.get_current_item(self)
  local state = _states[self._ctx_key]
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  return state.items[row]
end

function M.get_items(self)
  local state = _states[self._ctx_key]

  local selected_items = {}
  for _, item in ipairs(state.items) do
    local selected_item = state.selected_items[item.index]
    if selected_item then
      table.insert(selected_items, selected_item)
    end
  end

  if #selected_items == 0 then
    return { self:get_current_item() }
  end
  return selected_items
end

function M._redraw_sidecar(self)
  if not self._sidecar:enabled() then
    return
  end

  local item = self:get_current_item()
  if not item then
    return
  end

  local kind = require("thetto2.core.kind").new(item.kind_name)
  local promise, preview = kind:get_preview(item)
  self._sidecar:redraw(preview)
  return promise
end

function M.toggle_selection(self)
  local range = {
    vim.fn.line("v"),
    vim.fn.line("."),
  }
  table.sort(range, function(a, b)
    return a < b
  end)
  self:_toggle_selection(range[1], range[2])
end

function M.toggle_all_selection(self)
  local s = 1
  local e = vim.api.nvim_buf_line_count(self._bufnr)
  self:_toggle_selection(s, e)
end

function M._toggle_selection(self, s, e)
  local state = _states[self._ctx_key]

  local ranged_items = vim.list_slice(state.items, s, e)
  for _, item in ipairs(ranged_items) do
    local index = item.index
    if state.selected_items[index] then
      state.selected_items[index] = nil
    else
      state.selected_items[index] = item
    end
  end

  _states[self._ctx_key] = state

  vim.api.nvim__buf_redraw_range(self._bufnr, 0, -1)
end

return M
