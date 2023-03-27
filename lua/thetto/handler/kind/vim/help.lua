local M = {}

function M.action_open(items, _, ctx)
  for _, item in ipairs(items) do
    local err = M._open(item, "", "open", ctx)
    if err then
      return nil, err
    end
    vim.cmd.only()
  end
end

function M.action_tab_open(items, _, ctx)
  for _, item in ipairs(items) do
    local err = M._open(item, "tab", "tab_open", ctx)
    if err then
      return nil, err
    end
  end
end

function M.action_vsplit_open(items, _, ctx)
  for _, item in ipairs(items) do
    local err = M._open(item, "vertical", "vsplit_open", ctx)
    if err then
      return nil, err
    end
  end
end

function M._open(item, help_prefix, edit_action, ctx)
  local ok = pcall(vim.cmd, ("%s help %s"):format(help_prefix, item.value))
  if ok then
    return
  end

  local items = { item }
  local _, err = require("thetto.util.action").call("file", edit_action, items, ctx)
  if err then
    return err
  end

  vim.cmd.nohlsearch()
  vim.bo.buftype = "help"
  vim.bo.modifiable = false
end

function M.action_preview(_, _, ctx)
  local item = ctx.ui:current_item()
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
    local pattern = item.pattern:gsub("~", "\\~")
    vim.fn.search(pattern)
    vim.cmd.nohlsearch()
    return vim.api.nvim_win_get_cursor(0)
  end)

  return nil,
    ctx.ui:open_preview(item, {
      raw_bufnr = bufnr,
      row = cursor[1],
      range = { s = { column = cursor[2] }, e = { column = -1 } },
      title = vim.fn.fnamemodify(item.path, ":t"),
    })
end

M.default_action = "open"

return require("thetto.core.kind").extend(M, "file")
