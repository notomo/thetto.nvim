local M = {}

M.opts = {}

local to_git_root = require("thetto.handler.kind.git._util").to_git_root

M.opts.checkout = { track = false }
--- @async
function M.action_checkout(items, action_ctx)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = { "git", "checkout" }
  if action_ctx.opts.track then
    table.insert(cmd, "-t")
  end
  table.insert(cmd, item.value)

  return require("thetto.util.job").await(cmd, { cwd = item.git_root })
end

M.opts.delete = { force = false, args = { "--delete" } }
--- @async
function M.action_delete(items, action_ctx)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  vim.list_extend(cmd, action_ctx.opts.args)
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").await(cmd, { cwd = to_git_root(items) })
end

--- @async
function M.action_force_delete(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "delete", items, {
    args = { "-D" },
  })
end

--- @async
function M.action_rename(items)
  local item = items[1]
  if not item then
    return
  end

  local old_branch = item.value
  local new_branch = require("thetto.util.input").await({
    prompt = "Rename branch: ",
    default = old_branch,
  })
  if not new_branch or new_branch == "" or new_branch == old_branch then
    return require("thetto.lib.message").info("invalid input to rename branch: " .. tostring(new_branch))
  end

  require("thetto.util.job").await({ "git", "branch", "-m", old_branch, new_branch }, { cwd = item.git_root })
  return require("thetto.lib.message").info(("Renamed branch: %s -> %s"):format(old_branch, new_branch))
end

--- @async
function M.action_create(items)
  local item = items[1]
  if not item then
    return
  end

  local from = item.value
  local new_branch = require("thetto.util.input").await({
    prompt = ("Create branch from %s: "):format(from),
    default = from,
  })
  if not new_branch or new_branch == "" then
    return require("thetto.lib.message").info("invalid input to create branch: " .. tostring(new_branch))
  end

  require("thetto.util.job").await({ "git", "switch", "-c", new_branch, from }, { cwd = item.git_root })
  return require("thetto.lib.message").info(("Created branch from %s: %s"):format(from, new_branch))
end

function M.get_preview(item)
  return require("thetto.handler.kind.git._util").preview_diff(item)
end

--- @async
function M.action_merge(items)
  local item = items[1]
  if not item then
    return
  end
  return require("thetto.util.job").await({ "git", "merge", item.value }, { cwd = item.git_root })
end

--- @async
function M.action_tab_open(items)
  local item = items[1]
  if not item then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local content = require("thetto.util.git").content(item.git_root, bufnr, item.commit_hash)
  require("thetto.lib.buffer").open_scratch_tab()
  vim.cmd.edit({ args = { content.buffer_path }, magic = { file = false } })
  require("thetto.vendor.misclib.cursor").set(cursor)
end

M.default_action = "checkout"

return M
