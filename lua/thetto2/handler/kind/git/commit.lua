local M = {}

M.behaviors = {
  fixup = { quit = false },
  reword = { quit = false },
  reset = { quit = false },
  checkout = { quit = false },
  compare = { quit = false },
}

local open_diff = require("thetto2.handler.kind.git._util").open_diff

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
    require("thetto2.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(bufnr)
  end)
end

function M.get_preview(item)
  local bufnr = require("thetto2.util.git").diff_buffer()
  local promise = require("thetto2.handler.kind.git._util").render_diff(bufnr, item)
  return promise, { raw_bufnr = bufnr }
end

function M.action_fixup(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto2.util.job")
    .promise({ "git", "commit", "--fixup=" .. item.commit_hash }, { cwd = item.git_root })
    :next(function()
      return require("thetto2.command").reload(bufnr)
    end)
end

function M.action_reword(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto2.util.job")
    .promise({ "git", "commit", "--fixup=reword:" .. item.commit_hash }, { cwd = item.git_root })
    :next(function()
      return require("thetto2.command").reload(bufnr)
    end)
end

function M.action_rebase_interactively(items)
  local item = items[1]
  if not item then
    return nil
  end
  return require("thetto2.util.job").promise(
    { "git", "rebase", "-i", "--autosquash", item.commit_hash .. "~" },
    { cwd = item.git_root }
  )
end

function M.action_reset(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto2.util.job")
    .promise({ "git", "reset", item.commit_hash }, { cwd = item.git_root })
    :next(function()
      return require("thetto2.command").reload(bufnr)
    end)
end

function M.action_checkout(items)
  local item = items[1]
  if not item then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto2.util.job")
    .promise({ "git", "checkout", item.commit_hash }, { cwd = item.git_root })
    :next(function()
      return require("thetto2.command").reload(bufnr)
    end)
end

M.action_diff = M.action_tab_open

function M.action_list_children(items)
  local item = items[1]
  if not item then
    return nil
  end
  local source = require("thetto2.util.source").by_name("git/change", {
    opts = {
      commit_hash = item.commit_hash,
      path = item.path,
    },
  })
  return require("thetto2").start(source)
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
  return require("thetto2.util.git").compare(item.git_root, item.path, commit_hash .. "^", item.path, commit_hash)
end
--
M.default_action = "open"

return M
