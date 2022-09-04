local M = {}

local goto_item_pos = function(item)
  if item.bufnr then
    vim.cmd.buffer({ count = item.bufnr })
  end
  vim.api.nvim_win_set_cursor(0, { item.row, item.column or 0 })
end

function M.action_open(items)
  for _, item in ipairs(items) do
    goto_item_pos(item)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    vim.cmd.tabedit()
    goto_item_pos(item)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    vim.cmd.vsplit()
    goto_item_pos(item)
  end
end

function M.action_preview(items, _, ctx)
  local item = items[1]
  if item == nil then
    return
  end
  ctx.ui:open_preview(item, { bufnr = item.bufnr, row = item.row })
end

M.default_action = "open"

return M
