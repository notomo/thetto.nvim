local hl_groups = require("thetto.handler.consumer.ui.highlight_group")

--- @class ThettoUiItemListFooter
local M = {}
M.__index = M

local _states = {}

--- @param pipeline ThettoPipeline
function M.new(window_id, ctx_key, source_name, pipeline)
  local state = _states[ctx_key]
    or {
      status = "running",
      start_index = 1,
      end_index = 1,
      all_items_count = 0,
    }
  _states[ctx_key] = state

  local self = setmetatable({
    _window_id = window_id,
    _ctx_key = ctx_key,
    _source_name = source_name,
    _sorter_info = M._sorter_info(pipeline:sorters()),
  }, M)

  require("thetto.core.context").setup_expire(ctx_key, function()
    _states[ctx_key] = nil
  end)

  return self
end

function M.redraw(self, status, start_index, end_index, all_items_count)
  local state = vim.tbl_extend("keep", {
    status = status,
    start_index = start_index,
    end_index = end_index,
    all_items_count = all_items_count,
  }, _states[self._ctx_key])
  _states[self._ctx_key] = state

  vim.api.nvim_win_set_config(self._window_id, {
    footer = self:_line(),
    footer_pos = "left",
  })
end

function M._line(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  local state = _states[self._ctx_key]
  local line = ("%s%s [ %s - %s / %s , %s ] "):format(
    self._source_name,
    self._sorter_info,
    state.start_index,
    state.end_index,
    state.all_items_count,
    state.start_index + row - 1
  )
  return {
    { line, hl_groups.ThettoUiItemListFooter },
    { state.status, hl_groups.ThettoUiItemListFooter },
  }
end

function M._sorter_info(sorters)
  local sorter_names = vim
    .iter(sorters)
    :map(function(sorter)
      if sorter.desc then
        return ("%s:%s"):format(sorter.name, sorter.desc)
      end
      return ("%s"):format(sorter.name)
    end)
    :totable()

  if #sorter_names == 0 then
    return ""
  end

  return " sorter=" .. table.concat(sorter_names, ", ")
end

return M
