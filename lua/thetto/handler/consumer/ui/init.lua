--- @class ThettoUi
--- @field _item_list ThettoUiItemList
--- @field _inputter ThettoUiInputter
--- @field _sidecar ThettoUiSidecar
--- @field _closer ThettoUiCloser
local Ui = {}
Ui.__index = Ui

local default_opts = {
  has_sidecar = true,
  insert = true,
  display_limit = 500,
}

--- @param pipeline ThettoPipeline
function Ui.new(consumer_ctx, source, pipeline, callbacks, actions, item_cusor_factory, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts)

  local filters = pipeline:filters()

  local closer = require("thetto.handler.consumer.ui.closer").new()
  local layout = require("thetto.handler.consumer.ui.layout").new(opts.has_sidecar, filters)

  local sidecar =
    require("thetto.handler.consumer.ui.sidecar").open(consumer_ctx.ctx_key, opts.has_sidecar, layout.sidecar)

  local item_list = require("thetto.handler.consumer.ui.item_list").open(
    consumer_ctx.ctx_key,
    consumer_ctx.source_ctx.cwd,
    closer,
    layout.item_list,
    sidecar,
    consumer_ctx.item_cursor_row,
    source.highlight,
    consumer_ctx.source_ctx,
    pipeline,
    opts.insert,
    opts.display_limit,
    actions,
    source.name,
    item_cusor_factory
  )

  local inputter = require("thetto.handler.consumer.ui.inputter").open(
    consumer_ctx.ctx_key,
    consumer_ctx.source_ctx.cwd,
    closer,
    layout.inputter,
    callbacks.on_change,
    pipeline,
    opts.insert,
    source.name
  )

  closer:setup(function()
    local current_window_id = vim.api.nvim_get_current_win()
    local row = item_list:close(current_window_id)
    callbacks.on_row_changed(row)
    inputter:close(current_window_id)
    sidecar:close()
    callbacks.on_discard()
  end)

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
    _sidecar = sidecar,
    _closer = closer,
  }
  return setmetatable(tbl, Ui)
end

local consumer_events = require("thetto.core.consumer_events")

local handlers = {
  --- @param self ThettoUi
  [consumer_events.all.items_changed] = vim.schedule_wrap(function(self, items, all_items_count, pipeline_highlight)
    self._item_list:update_pipeline_highlight(pipeline_highlight)
    self._item_list:redraw_list(items, all_items_count)
  end),
  --- @param self ThettoUi
  [consumer_events.all.source_started] = vim.schedule_wrap(function(self, _, source_ctx)
    self._item_list:update_for_source_highlight(source_ctx)
    self._item_list:redraw_footer("running")
  end),
  --- @param self ThettoUi
  [consumer_events.all.source_completed] = vim.schedule_wrap(function(self)
    self._item_list:apply_item_cursor()
    self._item_list:redraw_footer("")
  end),
  [consumer_events.all.source_error] = function(_, err)
    vim.notify(err, vim.log.levels.ERROR)
  end,
}

function Ui.consume(self, event_name, ...)
  local handler = handlers[event_name]
  if not handler then
    return
  end
  return handler(self, ...)
end

local actions = {
  --- @param self ThettoUi
  move_to_input = function(self)
    self._inputter:enter()
  end,
  --- @param self ThettoUi
  move_to_list = function(self)
    self._item_list:enter()
  end,
  --- @param self ThettoUi
  quit = function(self)
    self._closer:execute()
  end,
  --- @param self ThettoUi
  toggle_selection = function(self)
    self._item_list:toggle_selection()
  end,
  --- @param self ThettoUi
  toggle_all_selection = function(self)
    self._item_list:toggle_all_selection()
  end,
  --- @param self ThettoUi
  increase_display_limit = function(self, increment)
    self._item_list:increase_display_limit(increment)
  end,
  --- @param self ThettoUi
  recall_history = function(self, offset)
    self._inputter:recall_history(offset)
  end,
  --- @param self ThettoUi
  wait = function(self)
    return self._inputter:promise()
  end,
}

function Ui.call(self, action_name, ...)
  local action = actions[action_name]
  if not action then
    return
  end
  return action(self, ...)
end

function Ui.get_items(self)
  return self._item_list:get_items()
end

function Ui.quit_fallback()
  local filetype = vim.bo.filetype
  if filetype ~= "thetto" and filetype ~= "thetto-inputter" then
    return
  end
  vim.api.nvim_win_close(0, true)
end

return Ui
