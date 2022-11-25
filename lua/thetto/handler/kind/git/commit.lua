local M = {}

M.behaviors = {
  fixup = { quit = false },
  reset = { quit = false },
  checkout = { quit = false },
}

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

function M.action_fixup(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto.util.job").promise({ "git", "commit", "--fixup=" .. item.commit_hash }):next(function()
    return require("thetto.command").reload(bufnr)
  end)
end

function M.action_rebase_interactively(items)
  local item = items[1]
  if not item then
    return nil
  end
  return require("thetto.util.job").promise({ "git", "rebase", "-i", "--autosquash", item.commit_hash .. "~" })
end

function M.action_reset(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto.util.job").promise({ "git", "reset", item.commit_hash }):next(function()
    return require("thetto.command").reload(bufnr)
  end)
end

function M.action_checkout(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto.util.job").promise({ "git", "checkout", item.commit_hash }):next(function()
    return require("thetto.command").reload(bufnr)
  end)
end

M.action_diff = M.action_tab_open

function M.action_list_children(items)
  local item = items[1]
  if not item then
    return nil
  end
  return require("thetto").start("git/change", { source_opts = { commit_hash = item.commit_hash } })
end

function M.action_compare(items)
  local item = items[1]
  if not item then
    return nil
  end
  if not item.path then
    return nil
  end
  local commit_hash = item.commit_hash or "HEAD"
  return require("thetto.handler.kind.git._util").compare(item.path, commit_hash .. "^", item.path, commit_hash)
end
--
M.default_action = "open"

return M
