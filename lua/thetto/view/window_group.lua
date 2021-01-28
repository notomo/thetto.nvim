local ItemList = require("thetto/view/item_list").ItemList
local Inputter = require("thetto/view/inputter").Inputter
local StatusLine = require("thetto/view/status_line").StatusLine
local Sidecar = require("thetto/view/sidecar").Sidecar
local vim = vim

local get_width = function()
  return math.floor(vim.o.columns * 0.6)
end

local get_column = function()
  return (vim.o.columns - get_width()) / 2
end

local M = {}

local WindowGroup = {}
WindowGroup.__index = WindowGroup
M.WindowGroup = WindowGroup

function WindowGroup.open(collector, active)
  local source_name = collector.source.name
  local input_lines = collector.input_lines

  local height = math.floor(vim.o.lines * 0.5)
  local width = get_width()
  local row = (vim.o.lines - height - #input_lines) / 2
  local column = get_column()

  local tbl = {}
  tbl.inputter = Inputter.new(collector, width, height, row, column)
  tbl.item_list = ItemList.new(source_name, collector.opts.display_limit, width, height, row, column)
  tbl.status_line = StatusLine.new(source_name, width, height, row, column)
  tbl.sidecar = Sidecar.new()

  local self = setmetatable(tbl, WindowGroup)

  if active == "input" then
    self.inputter:enter()
  else
    self.item_list:enter()
  end

  -- NOTICE: set autocmd in the end not to fire it
  self.item_list:enable_on_moved(source_name)

  return self
end

function WindowGroup.open_sidecar(self, item, open_target)
  if not self.item_list:is_valid() then
    return
  end

  local pos = self.item_list:position()
  local height = pos.height + self.inputter.height + 1
  local left_column = 2
  local width = get_width()
  local row = pos.row

  self:move_to(left_column)
  self.sidecar:open(item, open_target, width, height, row, left_column)
end

function WindowGroup.close_sidecar(self)
  self.sidecar:close()
  if not self.item_list:is_valid() then
    return
  end
  self:move_to(get_column())
end

function WindowGroup.close(self)
  self.item_list:close()
  self.inputter:close()
  self.status_line:close()
  self:close_sidecar()
end

function WindowGroup.move_to(self, left_column)
  self.item_list:move_to(left_column)
  self.inputter:move_to(left_column)
  self.status_line:move_to(left_column)
end

function WindowGroup.redraw(self, draw_ctx)
  if not self.item_list:is_valid() then
    return
  end

  local items = draw_ctx.items
  local source = draw_ctx.source
  local input_lines = draw_ctx.input_lines

  self.item_list:redraw(items, source, input_lines, draw_ctx.filters, draw_ctx.opts)
  self.status_line:redraw(source, items, draw_ctx.sorters, draw_ctx.finished, draw_ctx.result_count)
  self.inputter:redraw(input_lines, draw_ctx.filters)
end

function WindowGroup.is_valid(self)
  return self.item_list:is_valid() and self.inputter:is_valid() and self.status_line:is_valid()
end

vim.cmd("highlight default link ThettoSelected Statement")
vim.cmd("highlight default link ThettoInfo StatusLine")
vim.cmd("highlight default link ThettoColorLabelOthers StatusLine")
vim.cmd("highlight default link ThettoColorLabelBackground NormalFloat")
vim.cmd("highlight default link ThettoInput NormalFloat")
vim.cmd("highlight default link ThettoPreview Search")
vim.cmd("highlight default link ThettoFilterInfo Comment")

return M
