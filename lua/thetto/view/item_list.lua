local Context = require("thetto.core.context")
local windowlib = require("thetto.vendor.misclib.window")
local bufferlib = require("thetto.lib.buffer")
local cursorlib = require("thetto.lib.cursor")
local visual_mode = require("thetto.vendor.misclib.visual_mode")
local highlightlib = require("thetto.lib.highlight")
local Decorator = require("thetto.lib.decorator")
local vim = vim

local ItemList = {}
ItemList.__index = ItemList
ItemList.hl_ns_name = "thetto-list-highlight"

local FILETYPE = "thetto"

function ItemList.new(source_name, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    local name = ("thetto://%s/%s"):format(source_name, FILETYPE)
    bufferlib.delete_by_name(name)
    vim.api.nvim_buf_set_name(b, name)
    vim.bo[b].filetype = FILETYPE
  end)

  local border_char = "―"
  if vim.o.ambiwidth == "double" then
    border_char = "-"
  end
  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - 2, -- NOTICE: calc border width
    height = height - 1,
    relative = "editor",
    row = row,
    col = column,
    external = false,
    style = "minimal",
    border = {
      { " ", "NormalFloat" },
      { border_char, "ThettoAboveBorder" },
      { " ", "NormalFloat" },
      { " ", "NormalFloat" },
      { "", "NormalFloat" },
      { "", "NormalFloat" },
      { " ", "NormalFloat" },
      { " ", "NormalFloat" },
    },
  })

  local group_name = "theto_closed_" .. bufnr
  vim.api.nvim_create_augroup(group_name, {})
  vim.api.nvim_create_autocmd({ "WinClosed" }, {
    group = group_name,
    pattern = { "*" },
    callback = function(args)
      local ctx = Context.get(source_name)
      if not ctx then
        return
      end
      local id = tonumber(args.file)
      if not ctx.ui:has_window(id) then
        return
      end
      ctx.ui:close()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      require("thetto.command").reload(bufnr)
    end,
  })

  local tbl = {
    _bufnr = bufnr,
    _window = window,
    _group_name = group_name,
    _decorator = Decorator.factory(ItemList.hl_ns_name):create(bufnr, true),
  }
  local self = setmetatable(tbl, ItemList)
  self:enable_cursorline()
  return self
end

function ItemList.redraw(self, items)
  local lines = vim.tbl_map(function(item)
    return item.desc or item.value
  end, items)

  vim.bo[self._bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, lines)
  vim.bo[self._bufnr].modifiable = false

  if vim.api.nvim_win_is_valid(self._window) and vim.api.nvim_get_current_buf() ~= self._bufnr then
    vim.api.nvim_win_set_cursor(self._window, { 1, 0 })
  end
end

function ItemList.highlight(self, first_line, raw_items, source, filters, filter_ctxs, source_ctx)
  source.highlight(self._decorator, raw_items, first_line, source_ctx)

  self._decorator:filter("ThettoSelected", first_line, raw_items, function(item)
    return item.selected
  end)

  filters:highlight(filter_ctxs, self._bufnr, first_line, raw_items, self._decorator)
end

function ItemList.redraw_selections(self, s, e)
  vim.api.nvim__buf_redraw_range(self._bufnr, s, e)
end

function ItemList.move_to(self, left_column)
  local list_config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = list_config.row,
  })
  self:enable_cursorline()
end

function ItemList.is_valid(self)
  return vim.api.nvim_win_is_valid(self._window) and vim.api.nvim_buf_is_valid(self._bufnr)
end

function ItemList.is_active(self)
  return vim.api.nvim_get_current_win() == self._window
end

function ItemList.enable_cursorline(self)
  if not self:is_valid() then
    return
  end
  vim.wo[self._window].cursorline = true
end

function ItemList.enable_on_moved(self, source_name)
  local prev_row
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    buffer = self._bufnr,
    callback = function()
      if visual_mode.is_current() then
        return
      end
      local ctx = Context.get(source_name)
      if not ctx then
        return
      end

      local row = self:cursor()[1]
      if prev_row == row then
        return
      end
      prev_row = row

      ctx.ui:on_move()
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
    buffer = self._bufnr,
    command = "stopinsert",
  })
end

function ItemList.set_row(self, row)
  cursorlib.set_row(row, self._window, self._bufnr)
end

function ItemList.enter(self)
  windowlib.safe_enter(self._window)
end

function ItemList.close(self, is_passive)
  if self._closed then
    return
  end
  self._closed = true

  local ctx = Context.get_from_path(self._bufnr)
  if ctx and not is_passive then
    ctx:on_close()
  end

  vim.api.nvim_create_augroup(self._group_name, {})
  windowlib.safe_close(self._window)
end

function ItemList.position(self)
  local config = vim.api.nvim_win_get_config(self._window)
  return { height = config.height + 1, row = config.row }
end

function ItemList.cursor(self)
  return vim.api.nvim_win_get_cursor(self._window)
end

function ItemList.has(self, id)
  return self._window == id
end

ItemList.setup_highlight_groups = function()
  highlightlib.default("ThettoAboveBorder", {
    ctermbg = { "NormalFloat", 235 },
    guibg = { "NormalFloat", "#213243" },
    ctermfg = { "Comment", 103 },
    guifg = { "Comment", "#8d9eb2" },
  })
end

return ItemList
