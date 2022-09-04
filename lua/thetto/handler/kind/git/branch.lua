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

  return require("thetto.util.job").execute(cmd)
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

  return require("thetto.util.job").execute(cmd)
end

function M.action_force_delete(items, action_ctx, ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "execute", items, ctx, {
    args = { "-D" },
  })
end

M.default_action = "checkout"

return M
