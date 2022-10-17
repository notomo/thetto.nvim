local Context = require("thetto.core.context")
local Decorator = require("thetto.lib.decorator")
local windowlib = require("thetto.vendor.misclib.window")
local bufferlib = require("thetto.lib.buffer")
local vim = vim

local StatusLine = {}
StatusLine.__index = StatusLine

function StatusLine.new(source_name, width, height, row, column)
  local bufnr = bufferlib.scratch(function(b)
    vim.bo[b].modifiable = false
  end)

  local window = vim.api.nvim_open_win(bufnr, false, {
    width = width - 2,
    height = 1,
    relative = "editor",
    row = row + height,
    col = column,
    external = false,
    style = "minimal",
    border = {
      { "", "ThettoInfo" },
      { "", "ThettoInfo" },
      { " ", "ThettoInfo" },
      { " ", "ThettoInfo" },
      { "", "ThettoInfo" },
      { "", "ThettoInfo" },
      { " ", "ThettoInfo" },
      { " ", "ThettoInfo" },
    },
  })
  vim.wo[window].winhighlight = "Normal:ThettoInfo,CursorLine:ThettoInfo"
  vim.api.nvim_create_autocmd({ "WinEnter" }, {
    buffer = bufnr,
    callback = function()
      local ctx = Context.get(source_name)
      if not ctx then
        return
      end
      ctx.ui:into_inputter()
    end,
  })

  local tbl = {
    _window = window,
    _decorator_factory = Decorator.factory("thetto-info-text", bufnr),
  }
  return setmetatable(tbl, StatusLine)
end

function StatusLine.redraw(self, source, sorters, finished, start_index, end_index, result_count, item_list_row)
  local sorter_info = ""
  local sorter_names = {}
  for _, sorter in ipairs(sorters) do
    table.insert(sorter_names, sorter.name)
  end
  if #sorter_names > 0 then
    sorter_info = "  sorter=" .. table.concat(sorter_names, ", ")
  end

  local status = ""
  if not finished then
    status = "running"
  end

  local text = ("%s%s [ %s - %s / %s , %s ]"):format(
    source.name,
    sorter_info,
    start_index,
    end_index,
    result_count,
    start_index + item_list_row - 1
  )
  local decorator = self._decorator_factory:reset()
  decorator:add_virtual_text(0, 0, { { text, "ThettoInfo" }, { " " }, { status, "Comment" } }, {
    virt_text_pos = "overlay",
  })
end

function StatusLine.move_to(self, left_column)
  local config = vim.api.nvim_win_get_config(self._window)
  vim.api.nvim_win_set_config(self._window, {
    relative = "editor",
    col = left_column,
    row = config.row,
  })
end

function StatusLine.close(self)
  if self._closed then
    return
  end
  self._closed = true

  windowlib.safe_close(self._window)
end

function StatusLine.has(self, id)
  return self._window == id
end

return StatusLine
