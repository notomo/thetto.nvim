local M = {}

local open_diff = require("thetto.handler.kind.git._util").open_diff
local render_diff = require("thetto.handler.kind.git._util").render_diff

function M.action_open(items)
  return open_diff(items, function(bufnr)
    vim.cmd.buffer(bufnr)
  end)
end

function M.action_vsplit_open(items)
  return open_diff(items, function(bufnr)
    vim.cmd.vsplit()
    vim.cmd.buffer(bufnr)
  end)
end

function M.action_tab_open(items)
  return open_diff(items, function(bufnr)
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(bufnr)
  end)
end

function M.action_preview(items, _, ctx)
  local item = items[1]
  if not item then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local promise = render_diff(bufnr, item)
  ctx.ui:open_preview(item, { raw_bufnr = bufnr })
  return promise
end

M.default_action = "open"

return M
