--- @class ThettoUiItemListSelection
local M = {}
M.__index = M

local _resume_states = {}

function M.new(ctx_key, bufnr)
  local state = _resume_states[ctx_key] or {
    selected_items = {},
  }

  local self = setmetatable({
    _ctx_key = ctx_key,
    _bufnr = bufnr,

    _selected_items = state.selected_items,
  }, M)

  require("thetto.core.context").setup_expire(ctx_key, function()
    _resume_states[ctx_key] = nil
  end)

  return self
end

function M.toggle(self, items)
  local range = require("thetto.lib.visual_mode").range()
  self:_toggle(items, range[1], range[2])
end

function M.toggle_all(self, items)
  local s = 1
  local e = vim.api.nvim_buf_line_count(self._bufnr)
  self:_toggle(items, s, e)
end

function M._toggle(self, items, s, e)
  local ranged_items = vim.list_slice(items, s, e)
  for _, item in ipairs(ranged_items) do
    local index = item.index
    if self._selected_items[index] then
      self._selected_items[index] = nil
    else
      self._selected_items[index] = item
    end
  end

  vim.api.nvim__redraw({ buf = self._bufnr, range = { 0, -1 } })
end

function M.highlight(self, decorator, displayed_items, topline)
  local selected_items = self._selected_items
  decorator:filter("Statement", topline, displayed_items, function(item)
    return selected_items[item.index] ~= nil
  end)
end

function M.items(self, items)
  return vim
    .iter(items)
    :map(function(item)
      return self._selected_items[item.index]
    end)
    :totable()
end

function M.close(self)
  _resume_states[self._ctx_key] = {
    selected_items = self._selected_items,
  }
end

function M.count(self)
  return vim.tbl_count(self._selected_items)
end

return M
