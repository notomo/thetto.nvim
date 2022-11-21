local M = {}

local open_diff = require("thetto.handler.kind.git._util").open_diff

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

  local bufnr = require("thetto.handler.kind.git._util").diff_buffer()
  local promise = require("thetto.handler.kind.git._util").render_diff(bufnr, item)
  local err = ctx.ui:open_preview(item, { raw_bufnr = bufnr })
  if err then
    return nil, err
  end
  return promise
end

M.default_action = "open"

return M
