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
  change_display_limit = { offset = 1000 },
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
  reverse = { quit = false },
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
  resume_previous = { quit = false },
  resume_next = { quit = false },
  change_display_limit = { quit = false },
}

function M.action_toggle_selection(items, _, ctx)
  ctx.collector:toggle_selections(items)
end

function M.action_toggle_all_selection(_, _, ctx)
  ctx.collector:toggle_all_selections()
end

function M.action_move_to_input(_, action_ctx, ctx)
  ctx.ui:into_inputter()
  ctx.ui:start_insert(action_ctx.opts.behavior)
end

function M.action_move_to_list(_, _, ctx)
  ctx.ui:into_list()
  vim.cmd.stopinsert()
end

function M.action_quit(_, _, ctx)
  ctx.ui:close()
end

function M.action_debug_print(items)
  for _, item in ipairs(items) do
    require("thetto.vendor.misclib.message").info(vim.inspect(item))
  end
end

function M.action_debug_dump(items)
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = "json"

    local lines = { vim.json.encode(item) }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    vim.cmd.tabedit()
    vim.cmd.buffer(bufnr)
    vim.cmd("%!jq '.'")
  end
end

function M.action_echo(items)
  for _, item in ipairs(items) do
    require("thetto.vendor.misclib.message").info(item.value)
  end
end

function M.action_yank(items, action_ctx)
  local values = vim.tbl_map(function(item)
    return item[action_ctx.opts.key]
  end, items)
  local value = table.concat(values, "\n")
  if value ~= "" then
    vim.fn.setreg(action_ctx.opts.register, value)
    require("thetto.vendor.misclib.message").info("yank: " .. value)
  end
end

function M.action_append(items, action_ctx)
  for _, item in ipairs(items) do
    vim.api.nvim_put({ item[action_ctx.opts.key] }, action_ctx.opts.type, true, true)
  end
end

function M.action_add_filter(_, action_ctx, ctx)
  local filter_name = action_ctx.opts.name
  return ctx.collector:add_filter(filter_name)
end

function M.action_remove_filter(_, action_ctx, ctx)
  local filter_name = action_ctx.opts.name or ctx.ui:current_position_filter().name
  return ctx.collector:remove_filter(filter_name)
end

function M.action_inverse_filter(_, action_ctx, ctx)
  local filter_name = action_ctx.opts.name or ctx.ui:current_position_filter().name
  return ctx.collector:inverse_filter(filter_name)
end

function M.action_change_filter(_, action_ctx, ctx)
  local old_filter_name = ctx.ui:current_position_filter().name
  return ctx.collector:change_filter(old_filter_name, action_ctx.opts.name)
end

function M.action_reverse(_, _, ctx)
  return ctx.collector:reverse()
end

function M.action_reverse_sorter(_, action_ctx, ctx)
  if ctx.collector.sorters:length() == 0 then
    return nil, "no sorter"
  end
  return ctx.collector:reverse_sorter(action_ctx.opts.name or ctx.collector.sorters[1].name)
end

function M.action_toggle_sorter(_, action_ctx, ctx)
  local sorter_name = action_ctx.opts.name
  return ctx.collector:toggle_sorter(sorter_name)
end

function M.action_toggle_preview(items, _, ctx)
  if ctx.ui:exists_same_preview(items) then
    return ctx.ui:close_preview()
  end
  return ctx.executor:actions(items, ctx, "preview", {})
end

function M.action_close_preview(_, _, ctx)
  ctx.ui:close_preview()
end

function M.action_resume_previous(_, action_ctx, ctx)
  local previous_ctx = ctx:resume_previous()
  if previous_ctx then
    return previous_ctx.ui:resume()
  end
  if action_ctx.opts.wrap then
    local first_ctx = require("thetto.core.context").resume()
    if first_ctx then
      return first_ctx.ui:resume()
    end
  end
  return nil, "no context"
end

function M.action_resume_next(_, action_ctx, ctx)
  local next_ctx = ctx:resume_next()
  if next_ctx then
    return next_ctx.ui:resume()
  end
  if action_ctx.opts.wrap then
    local last_ctx = ctx:resume_last()
    if last_ctx then
      return last_ctx.ui:resume()
    end
  end
  return nil, "no context"
end

function M.action_go_to_next_page(_, _, ctx)
  return ctx.collector:change_page_offset(1)
end

function M.action_go_to_previous_page(_, _, ctx)
  return ctx.collector:change_page_offset(-1)
end

function M.action_change_display_limit(_, action_ctx, ctx)
  return ctx.collector:change_display_limit(action_ctx.opts.offset)
end

function M.action_append_filter_input(items, _, ctx)
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
