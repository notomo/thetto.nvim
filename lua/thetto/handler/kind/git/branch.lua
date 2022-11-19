local M = {}

M.opts = {}

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

  return require("thetto.util.job").promise(cmd)
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

  return require("thetto.util.job").promise(cmd)
end

function M.action_force_delete(items, action_ctx, ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "execute", items, ctx, {
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
      return require("thetto.util.job").promise({ "git", "branch", "-m", old_branch, new_branch }):next(function()
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
      return require("thetto.util.job").promise({ "git", "switch", "-c", new_branch, from }):next(function()
        return require("thetto.vendor.misclib.message").info(("Created branch from %s: %s"):format(from, new_branch))
      end)
    end)
end

function M.action_preview(items, _, ctx)
  local item = items[1]
  if not item then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local promise = require("thetto.handler.kind.git._util").render_diff(bufnr, item)
  local err = ctx.ui:open_preview(item, { raw_bufnr = bufnr })
  if err then
    return nil, err
  end
  return promise
end

M.default_action = "checkout"

return M
