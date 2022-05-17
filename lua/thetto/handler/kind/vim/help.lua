local M = {}

function M.action_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "", "action_open")
    vim.cmd("only")
  end
end

function M.action_tab_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "tab", "action_tab_open")
  end
end

function M.action_vsplit_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "vertical", "action_vsplit_open")
  end
end

local file_kind = require("thetto.handler.kind.file")

function M._open(self, item, help_prefix, edit_action)
  local ok = pcall(vim.cmd, ("%s help %s"):format(help_prefix, item.value))
  if ok then
    return
  end
  file_kind[edit_action](self, { item })
  vim.cmd([[nohlsearch]])
  vim.bo.buftype = "help"
  vim.bo.modifiable = false
end

function M.action_preview(_, items, ctx)
  local item = items[1]
  if item == nil then
    return
  end

  local help_bufnr = vim.fn.bufadd(item.path)
  vim.fn.bufload(help_bufnr)
  local lines = vim.api.nvim_buf_get_lines(help_bufnr, 0, -1, false)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = "help"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  local cursor = vim.api.nvim_buf_call(bufnr, function()
    vim.fn.search(item.pattern)
    vim.cmd([[nohlsearch]])
    return vim.api.nvim_win_get_cursor(0)
  end)

  ctx.ui:open_preview(
    item,
    { raw_bufnr = bufnr, row = cursor[1], range = { s = { column = cursor[2] }, e = { column = -1 } } }
  )
end

M.default_action = "open"

return require("thetto.core.kind").extend(M, "file")
