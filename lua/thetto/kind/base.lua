local M = {}

M.opts = {
  yank = {key = "value", register = "+"},
  append = {key = "value", type = ""},
  add_filter = {name = "substring"},
  remove_filter = {name = nil},
  change_filter = {name = nil},
  reverse_sorter = {name = nil},
  move_to_input = {behavior = "i"},
}

M.behaviors = {
  move_to_input = {quit = false},
  move_to_list = {quit = false},
  debug_print = {quit = false},
  toggle_selection = {quit = false},
  toggle_all_selection = {quit = false},
  add_filter = {quit = false},
  remove_filter = {quit = false},
  inverse_filter = {quit = false},
  change_filter = {quit = false},
  reverse_sorter = {quit = false},
  toggle_sorter = {quit = false},
  preview = {quit = false},
  toggle_preview = {quit = false},
  close_preview = {quit = false},
}

M.action_toggle_selection = function(_, items, ctx)
  ctx.collector:toggle_selections(items)
end

M.action_toggle_all_selection = function(_, _, ctx)
  ctx.collector:toggle_all_selections()
end

M.action_move_to_input = function(self, _, ctx)
  ctx.ui:enter("input")
  ctx.ui:start_insert(self.action_opts.behavior)
end

M.action_move_to_list = function(_, _, ctx)
  ctx.ui:enter("list")
  vim.cmd("stopinsert")
end

M.action_quit = function(_, _, ctx)
  ctx.ui:close()
end

M.action_debug_print = function(_, items)
  for _, item in ipairs(items) do
    print(vim.inspect(item))
  end
end

M.action_echo = function(_, items)
  for _, item in ipairs(items) do
    print(item.value)
  end
end

M.action_yank = function(self, items)
  local values = vim.tbl_map(function(item)
    return item[self.action_opts.key]
  end, items)
  local value = table.concat(values, "\n")
  if value ~= "" then
    vim.fn.setreg(self.action_opts.register, value)
    print("yank: " .. value)
  end
end

M.action_append = function(self, items)
  for _, item in ipairs(items) do
    vim.api.nvim_put({item[self.action_opts.key]}, self.action_opts.type, true, true)
  end
end

M.action_add_filter = function(self, _, ctx)
  local filter_name = self.action_opts.name
  ctx.collector:add_filter(filter_name)
end

M.action_remove_filter = function(self, _, ctx)
  local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
  return nil, ctx.collector:remove_filter(filter_name)
end

M.action_inverse_filter = function(self, _, ctx)
  local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
  ctx.collector:inverse_filter(filter_name)
end

M.action_change_filter = function(self, _, ctx)
  local old_filter_name = ctx.ui:current_position_filter().name
  return nil, ctx.collector:change_filter(old_filter_name, self.action_opts.name)
end

M.action_reverse_sorter = function(self, _, ctx)
  local sorter_name = self.action_opts.name or ctx.ui:current_position_sorter().name
  ctx.collector:reverse_sorter(sorter_name)
end

M.action_toggle_sorter = function(self, _, ctx)
  local sorter_name = self.action_opts.name
  return nil, ctx.collector:toggle_sorter(sorter_name)
end

M.action_preview = function(_, _, ctx)
  return ctx.ui:open_preview(nil, {})
end

M.action_toggle_preview = function(self, items, ctx)
  if ctx.ui:exists_same_preview(items) then
    ctx.ui:close_preview()
  else
    return self.executor:action(ctx, "preview", self.name, items)
  end
end

M.action_close_preview = function(_, _, ctx)
  ctx.ui:close_preview()
end

M.default_action = "echo"

M.__index = M
setmetatable(M, {})

return M
