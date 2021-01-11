local M = {}

M.after = function(_, _)
  vim.cmd("nohlsearch")
end

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    local cmd = item.range_part .. item.excmd
    vim.cmd(cmd)
    M.after(item.value, cmd)
  end
end

M.action_preview = function(self, items, ctx)
  local item = items[1]
  if item == nil then
    return
  end

  local first = 0
  local last = -1
  if item.range ~= nil then
    first = item.range.first - 1
    last = item.range.last
  end

  local lines = vim.api.nvim_buf_get_lines(item.bufnr, first, last, false)
  local preview_item = vim.deepcopy(item)
  preview_item.range_part = ("1,%d"):format(#lines)

  ctx.ui:open_preview(preview_item, {
    lines = lines,
    execute = function()
      M.action_execute(self, {preview_item})
    end,
  })
end

M.default_action = "execute"

return M
