local filelib = require("thetto.lib.file")

local M = {}

function M.action_open(items)
  for _, item in ipairs(items) do
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    vim.cmd.vsplit()
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_tab_drop(items)
  for _, item in ipairs(items) do
    local path = vim.api.nvim_buf_get_name(item.bufnr)
    if path ~= "" then
      vim.cmd.drop({ mods = { tab = 0 }, args = { filelib.escape(path) } })
    end
  end
end

function M.action_preview(_, _, ctx)
  local item = ctx.ui:current_item()
  if item == nil or not vim.api.nvim_buf_is_loaded(item.bufnr) then
    return
  end
  return nil, ctx.ui:open_preview(item, { bufnr = item.bufnr })
end

M.default_action = "open"

return M