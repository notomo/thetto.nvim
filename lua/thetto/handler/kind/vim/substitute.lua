local M = {}

function M.after(_, _)
  vim.cmd("nohlsearch")
end

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    local cmd = item.cmd_prefix .. item.excmd
    vim.cmd(cmd)
    M.after(item.value, cmd)
  end
end

function M.action_preview(_, items, ctx)
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

  if not vim.api.nvim_buf_is_valid(item.bufnr) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(item.bufnr, first, last, false)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"

  vim.api.nvim_buf_call(bufnr, function()
    local cmd = ("silent! 1,%d%s"):format(#lines, item.excmd)
    vim.cmd(cmd)
    M.after(item.value, cmd)
  end)

  ctx.ui:open_preview(item, { raw_bufnr = bufnr })
end

M.default_action = "execute"

return M
