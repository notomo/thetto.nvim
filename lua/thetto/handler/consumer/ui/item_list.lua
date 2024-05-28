local hl_groups = require("thetto.handler.consumer.ui.highlight_group")

--- @class ThettoUiItemList
--- @field _closed boolean
--- @field _sidecar ThettoUiSidecar
--- @field _footer ThettoUiItemListFooter
--- @field _actions table
--- @field _pipeline_highlight fun(...)
--- @field _items table
--- @field _page integer
--- @field _display_limit integer
--- @field _selection ThettoUiItemListSelection
--- @field _item_cursor_factory ThettoItemCursorFactory
--- @field _source_ctx ThettoSourceContext
local M = {}
M.__index = M

local _ns_name = "thetto-list-highlight"
local _ns = vim.api.nvim_create_namespace(_ns_name)

local _selfs = {}
local _resume_states = {}

--- @param sidecar ThettoUiSidecar
--- @param pipeline ThettoPipeline
function M.open(
  ctx_key,
  cwd,
  closer,
  layout,
  sidecar,
  item_cursor_row,
  source_highlight,
  source_ctx,
  pipeline,
  insert,
  display_limit,
  actions,
  source_name,
  item_cursor_factory
)
  local state = _resume_states[ctx_key]
    or {
      has_forcus = not insert,
      column = 0,

      items = {},
      page = 0,
      display_limit = display_limit,
      source_ctx = source_ctx,
    }

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/list"):format(ctx_key))

  local path = vim.fn.fnamemodify(cwd, ":~")
  local trim_length = vim.fn.strchars(path) - layout.width
  if 0 < trim_length then
    path = ".." .. vim.fn.strpart(path, trim_length + 4 * 2)
  end
  local title = (" %s "):format(path)

  local window_id = vim.api.nvim_open_win(bufnr, state.has_forcus, {
    width = layout.width,
    height = layout.height,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    title = { { title, hl_groups.ThettoUiItemListTitle } },
    title_pos = "center",
    border = {
      { " ", hl_groups.ThettoUiBorder },
      { layout.border_char, hl_groups.ThettoUiAboveBorder },
      { " ", hl_groups.ThettoUiBorder },
      { " ", hl_groups.ThettoUiBorder },
      { " ", hl_groups.ThettoUiItemListFooter },
      { " ", hl_groups.ThettoUiItemListFooter },
      { " ", hl_groups.ThettoUiItemListFooter },
      { " ", hl_groups.ThettoUiBorder },
    },
  })
  vim.wo[window_id].winfixbuf = true
  local footer = require("thetto.handler.consumer.ui.item_list_footer").new(window_id, ctx_key, source_name, pipeline)
  footer:redraw()

  require("thetto.handler.consumer.ui.current_dir").apply(window_id, cwd)

  closer:setup_autocmd(window_id)
  require("thetto.core.context").setup_expire(ctx_key, function()
    _resume_states[ctx_key] = nil
  end)

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      require("thetto").reload(bufnr)
    end,
  })

  vim.api.nvim_exec_autocmds("User", {
    pattern = "ThettoOpened",
    data = {
      source_name = source_name,
      list_bufnr = bufnr,
    },
  })

  local self = setmetatable({
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _sidecar = sidecar,
    _footer = footer,
    _selection = require("thetto.handler.consumer.ui.item_list_selection").new(ctx_key, bufnr),
    _decorator = require("thetto.lib.decorator").factory(_ns_name):create(bufnr, true),
    _filters = pipeline:filters(),
    _actions = actions,

    _source_highlight = source_highlight or function() end,
    _pipeline_highlight = function() end,
    _closed = false,

    _items = state.items,
    _page = state.page,
    _display_limit = state.display_limit,
    _source_ctx = state.source_ctx,
    _item_cursor_factory = item_cursor_factory,
  }, M)
  _selfs[bufnr] = self

  self:redraw_list(self._items)
  vim.api.nvim_win_set_cursor(window_id, { item_cursor_row, state.column })

  local on_cursor_moved = require("thetto.lib.debounce").promise(100, function()
    if self._closed then
      return
    end

    self:redraw_footer()
    return self:_redraw_sidecar()
  end)
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    buffer = bufnr,
    callback = function()
      on_cursor_moved()
    end,
  })
  vim.api.nvim_create_autocmd({ "WinEnter" }, {
    buffer = bufnr,
    callback = function()
      vim.cmd.stopinsert()
    end,
  })

  vim.api.nvim_set_decoration_provider(_ns, {})
  vim.api.nvim_set_decoration_provider(_ns, {
    on_win = function(_, _, self_bufnr, topline, botline_guess)
      local item_list = _selfs[self_bufnr] ---@type ThettoUiItemList
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
  if self._closed then
    return
  end

  self._items = items

  local items_count = #self._items
  local page = math.min(self._page, math.floor(items_count / self._display_limit))

  local start_index = 1 + self._display_limit * page
  start_index = math.min(items_count, start_index)

  local end_index = self._display_limit * (page + 1)
  end_index = math.min(items_count, end_index)

  local index = 1
  local paged_items = {}
  for i = start_index, end_index, 1 do
    paged_items[index] = items[i]
    index = index + 1
  end

  local lines = vim
    .iter(paged_items)
    :map(function(item)
      return item.desc or item.value
    end)
    :totable()

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
  vim.bo[self._bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self._window_id) and vim.api.nvim_get_current_buf() ~= self._bufnr then
    vim.api.nvim_win_set_cursor(self._window_id, { 1, 0 })
  end

  self:redraw_footer(nil, start_index, end_index, all_items_count)
  self:_redraw_sidecar()
end

function M.redraw_footer(self, status, start_index, end_index, all_items_count)
  if self._closed then
    return
  end
  self._footer:redraw(status, start_index, end_index, all_items_count, self._selection:count())
end

function M.apply_item_cursor(self)
  if self._closed then
    return
  end

  local item_cursor = self._item_cursor_factory(self._items)
  local row, column = unpack(vim.api.nvim_win_get_cursor(self._window_id))
  row = item_cursor:apply(row, vim.api.nvim_buf_line_count(self._bufnr))
  vim.api.nvim_win_set_cursor(self._window_id, { row, column })
end

function M.update_for_source_highlight(self, source_ctx)
  self._source_ctx = source_ctx
end

function M.update_pipeline_highlight(self, pipeline_highlight)
  self._pipeline_highlight = pipeline_highlight
end

function M.highlight(self, topline, botline_guess)
  local items = self._items

  local displayed_items = {}
  for i = topline + 1, botline_guess + 1, 1 do
    table.insert(displayed_items, items[i])
  end

  self._source_highlight(self._decorator, displayed_items, topline, self._source_ctx)
  self._pipeline_highlight(self._decorator, displayed_items, topline)
  self._selection:highlight(self._decorator, displayed_items, topline)
end

function M.enter(self)
  require("thetto.vendor.misclib.window").safe_enter(self._window_id)
end

function M.close(self, current_window_id)
  if self._closed then
    return 1
  end
  self._closed = true
  _selfs[self._bufnr] = nil

  local row, column = unpack(vim.api.nvim_win_get_cursor(self._window_id))
  _resume_states[self._ctx_key] = {
    has_forcus = current_window_id == self._window_id,
    column = column,

    items = self._items,
    page = self._page,
    display_limit = self._display_limit,
    source_ctx = self._source_ctx,
  }

  self._footer:close()
  self._selection:close()

  require("thetto.vendor.misclib.window").safe_close(self._window_id)
  vim.api.nvim_set_decoration_provider(_ns, {})

  return row
end

function M._get_row_items(self, s, e)
  return vim.list_slice(self._items, s, e)
end

function M.get_current_item(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  return self._items[row]
end

function M.get_items(self)
  local selected_items = self._selection:items(self._items)
  if #selected_items > 0 then
    return selected_items
  end

  local range = require("thetto.lib.visual_mode").range()
  return self:_get_row_items(range[1], range[2])
end

function M._redraw_sidecar(self)
  if not self._sidecar:enabled() then
    return
  end

  local item = self:get_current_item()
  if not item then
    return
  end

  local kind = require("thetto.core.kind").by_name(item.kind_name, self._actions)
  local promise, preview = require("thetto.core.kind").get_preview(kind, item)
  self._sidecar:redraw(preview)
  return promise
end

function M.toggle_selection(self)
  self._selection:toggle(self._items)
end

function M.toggle_all_selection(self)
  self._selection:toggle_all(self._items)
end

function M.increase_display_limit(self, increment)
  increment = increment or 1000
  self._display_limit = self._display_limit + increment
  self:redraw_list(self._items)
end

return M
