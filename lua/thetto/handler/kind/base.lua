local M = {}

M.opts = {
  yank = { key = "value", register = "+" },
  append = { key = "value", type = "" },
  add_filter = { name = "substring" },
  remove_filter = { name = nil },
  change_filter = { name = nil },
  reverse_sorter = { name = nil },
  move_to_input = { behavior = "i" },
  resume_previous = { wrap = true },
  resume_next = { wrap = true },
}

M.behaviors = {
  move_to_input = { quit = false },
  move_to_list = { quit = false },
  debug_print = { quit = false },
  toggle_selection = { quit = false },
  toggle_all_selection = { quit = false },
  add_filter = { quit = false },
  remove_filter = { quit = false },
  inverse_filter = { quit = false },
  change_filter = { quit = false },
  reverse_sorter = { quit = false },
  toggle_sorter = { quit = false },
  preview = { quit = false },
  toggle_preview = { quit = false },
  close_preview = { quit = false },
  go_to_next_page = { quit = false },
  go_to_previous_page = { quit = false },
  append_filter_input = { quit = false },
  recall_previous_history = { quit = false },
  recall_next_history = { quit = false },
}

function M.action_toggle_selection(_, items, ctx)
  ctx.collector:toggle_selections(items)
end

function M.action_toggle_all_selection(_, _, ctx)
  ctx.collector:toggle_all_selections()
end

function M.action_move_to_input(self, _, ctx)
  ctx.ui:into_inputter()
  ctx.ui:start_insert(self.action_opts.behavior)
end

function M.action_move_to_list(_, _, ctx)
  ctx.ui:into_list()
  vim.cmd("stopinsert")
end

function M.action_quit(_, _, ctx)
  ctx.ui:close()
end

function M.action_debug_print(_, items)
  for _, item in ipairs(items) do
    print(vim.inspect(item))
  end
end

function M.action_echo(_, items)
  for _, item in ipairs(items) do
    print(item.value)
  end
end

function M.action_yank(self, items)
  local values = vim.tbl_map(function(item)
    return item[self.action_opts.key]
  end, items)
  local value = table.concat(values, "\n")
  if value ~= "" then
    vim.fn.setreg(self.action_opts.register, value)
    print("yank: " .. value)
  end
end

function M.action_append(self, items)
  for _, item in ipairs(items) do
    vim.api.nvim_put({ item[self.action_opts.key] }, self.action_opts.type, true, true)
  end
end

function M.action_add_filter(self, _, ctx)
  local filter_name = self.action_opts.name
  ctx.collector:add_filter(filter_name)
end

function M.action_remove_filter(self, _, ctx)
  local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
  return nil, ctx.collector:remove_filter(filter_name)
end

function M.action_inverse_filter(self, _, ctx)
  local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
  ctx.collector:inverse_filter(filter_name)
end

function M.action_change_filter(self, _, ctx)
  local old_filter_name = ctx.ui:current_position_filter().name
  return nil, ctx.collector:change_filter(old_filter_name, self.action_opts.name)
end

function M.action_reverse_sorter(self, _, ctx)
  if ctx.collector.sorters:length() == 0 then
    return nil, "no sorter"
  end
  return nil, ctx.collector:reverse_sorter(self.action_opts.name or ctx.collector.sorters[1].name)
end

function M.action_toggle_sorter(self, _, ctx)
  local sorter_name = self.action_opts.name
  return nil, ctx.collector:toggle_sorter(sorter_name)
end

function M.action_preview(_, _, ctx)
  return ctx.ui:open_preview(nil, {})
end

function M.action_toggle_preview(self, items, ctx)
  if ctx.ui:exists_same_preview(items) then
    ctx.ui:close_preview()
  else
    return self.executor:action(items, ctx, "preview")
  end
end

function M.action_close_preview(_, _, ctx)
  ctx.ui:close_preview()
end

function M.action_resume_previous(self, _, ctx)
  local previous_ctx = ctx:resume_previous()
  if previous_ctx then
    return nil, previous_ctx.ui:resume()
  end
  if self.action_opts.wrap then
    local first_ctx = require("thetto.core.context").resume()
    if first_ctx then
      return nil, first_ctx.ui:resume()
    end
  end
  return nil, "no context"
end

function M.action_resume_next(self, _, ctx)
  local next_ctx = ctx:resume_next()
  if next_ctx then
    return nil, next_ctx.ui:resume()
  end
  if self.action_opts.wrap then
    local last_ctx = ctx:resume_last()
    if last_ctx then
      return nil, last_ctx.ui:resume()
    end
  end
  return nil, "no context"
end

function M.action_go_to_next_page(_, _, ctx)
  ctx.collector:change_page_offset(1)
end

function M.action_go_to_previous_page(_, _, ctx)
  ctx.collector:change_page_offset(-1)
end

function M.action_append_filter_input(_, items, ctx)
  local item = items[1]
  if not (item and item.value) then
    return
  end
  ctx.ui:append_input(item.value)
end

function M.action_recall_previous_history(_, _, ctx)
  ctx.ui:recall_history(1)
end

function M.action_recall_next_history(_, _, ctx)
  ctx.ui:recall_history(-1)
end

M.default_action = "echo"

return M
