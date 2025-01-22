local M = {}

function M.action_open(items)
  for _, item in ipairs(items) do
    local err = M._open(item, "", "open")
    if err then
      return err
    end
    vim.cmd.only()
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    local err = M._open(item, "tab", "tab_open")
    if err then
      return err
    end
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    local err = M._open(item, "vertical", "vsplit_open")
    if err then
      return err
    end
  end
end

function M._open(item, help_prefix, edit_action)
  local ok = pcall(function()
    vim.cmd(("%s help %s"):format(help_prefix, item.value))
  end)
  if ok then
    return
  end

  local items = { item }
  local _, err = require("thetto.util.action").call("file", edit_action, items)
  if err then
    return err
  end

  vim.cmd.nohlsearch()
  vim.bo.buftype = "help"
  vim.bo.modifiable = false
end

function M.get_preview(item)
  local help_bufnr = vim.fn.bufadd(item.path)
  vim.fn.bufload(help_bufnr)
  local lines = vim.api.nvim_buf_get_lines(help_bufnr, 0, -1, false)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = "help"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  local cursor = vim.api.nvim_buf_call(bufnr, function()
    vim.fn.search(item.pattern)
    vim.cmd.nohlsearch()
    return vim.api.nvim_win_get_cursor(0)
  end)

  return nil,
    {
      raw_bufnr = bufnr,
      row = cursor[1],
      column = cursor[2],
      end_column = -1,
      title = vim.fs.basename(item.path),
    }
end

M.default_action = "open"

return require("thetto.core.kind").extend(M, "file")
