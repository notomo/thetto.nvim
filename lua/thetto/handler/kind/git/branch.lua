local M = {}

M.opts = {}

local to_git_root = require("thetto.handler.kind.git._util").to_git_root

M.opts.checkout = { track = false }
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

  return require("thetto.util.job").promise(cmd, { cwd = item.git_root })
end

M.opts.delete = { force = false, args = { "--delete" } }
function M.action_delete(items, action_ctx)
  local branches = {}
  for _, item in ipairs(items) do
    table.insert(branches, item.value)
  end

  local cmd = { "git", "branch" }
  vim.list_extend(cmd, action_ctx.opts.args)
  vim.list_extend(cmd, branches)

  return require("thetto.util.job").promise(cmd, { cwd = to_git_root(items) })
end

function M.action_force_delete(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "delete", items, {
    args = { "-D" },
  })
end

function M.action_rename(items)
  local item = items[1]
  if not item then
    return
  end

  local old_branch = item.value
  local new_branch
  return require("thetto.util.input")
    .promise({
      prompt = "Rename branch: ",
      default = old_branch,
    })
    :next(function(input)
      if not input or input == "" or input == old_branch then
        return require("thetto.vendor.misclib.message").info("invalid input to rename branch: " .. tostring(input))
      end
      new_branch = input
      return require("thetto.util.job")
        .promise({ "git", "branch", "-m", old_branch, new_branch }, { cwd = item.git_root })
        :next(function()
          return require("thetto.vendor.misclib.message").info(
            ("Renamed branch: %s -> %s"):format(old_branch, new_branch)
          )
        end)
    end)
end

function M.action_create(items)
  local item = items[1]
  if not item then
    return
  end

  local from = item.value
  local new_branch
  return require("thetto.util.input")
    .promise({
      prompt = ("Create branch from %s: "):format(from),
      default = from,
    })
    :next(function(input)
      if not input or input == "" then
        return require("thetto.vendor.misclib.message").info("invalid input to create branch: " .. tostring(new_branch))
      end
      new_branch = input
      return require("thetto.util.job")
        .promise({ "git", "switch", "-c", new_branch, from }, { cwd = item.git_root })
        :next(function()
          return require("thetto.vendor.misclib.message").info(("Created branch from %s: %s"):format(from, new_branch))
        end)
    end)
end

function M.get_preview(item)
  local bufnr = require("thetto.util.git").diff_buffer()
  local promise = require("thetto.handler.kind.git._util").render_diff(bufnr, item)
  return promise, { raw_bufnr = bufnr }
end

function M.action_merge(items)
  local item = items[1]
  if not item then
    return
  end
  return require("thetto.util.job").promise({ "git", "merge", item.value }, { cwd = item.git_root })
end

function M.action_tab_open(items)
  local item = items[1]
  if not item then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return require("thetto.util.git").content(item.git_root, bufnr, item.commit_hash):next(function(buffer_path)
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.edit(require("thetto.lib.file").escape(buffer_path))
    require("thetto.vendor.misclib.cursor").set(cursor)
  end)
end

M.default_action = "checkout"

return M
