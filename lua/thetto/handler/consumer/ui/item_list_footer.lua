local hl_groups = require("thetto.handler.consumer.ui.highlight_group")

--- @class ThettoUiItemListFooter
--- @field _status string
--- @field _start_index integer
--- @field _end_index integer
--- @field _all_items_count integer
local M = {}
M.__index = M

local _resume_states = {}

--- @param pipeline ThettoPipeline
function M.new(window_id, ctx_key, source_name, pipeline)
  local state = _resume_states[ctx_key]
    or {
      status = "running",
      start_index = 1,
      end_index = 1,
      all_items_count = 0,
    }

  local self = setmetatable({
    _window_id = window_id,
    _ctx_key = ctx_key,
    _source_name = source_name,
    _sorter_info = M._sorter_info(pipeline:sorters()),

    _status = state.status,
    _start_index = state.start_index,
    _end_index = state.end_index,
    _all_items_count = state.all_items_count,
  }, M)

  require("thetto.core.context").setup_expire(ctx_key, function()
    _resume_states[ctx_key] = nil
  end)

  return self
end

function M.redraw(self, status, start_index, end_index, all_items_count)
  self._status = status or self._status
  self._start_index = start_index or self._start_index
  self._end_index = end_index or self._end_index
  self._all_items_count = all_items_count or self._all_items_count

  vim.api.nvim_win_set_config(self._window_id, {
    footer = self:_line(),
    footer_pos = "left",
  })
end

function M._line(self)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  local line = ("%s%s [ %s - %s / %s , %s ] "):format(
    self._source_name,
    self._sorter_info,
    self._start_index,
    self._end_index,
    self._all_items_count,
    self._start_index + row - 1
  )
  return {
    { line, hl_groups.ThettoUiItemListFooter },
    { self._status, hl_groups.ThettoUiItemListFooter },
  }
end

function M.close(self)
  _resume_states[self._ctx_key] = {
    status = self._status,
    start_index = self._start_index,
    end_index = self._end_index,
    all_items_count = self._all_items_count,
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
