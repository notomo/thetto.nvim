local M = {}

function M.to_git_root(items)
  return items[1].git_root
end

function M.render_diff(bufnr, item)
  local cmd = { "git", "--no-pager", "show", "--date=iso" }
  local target = item.commit_hash or item.stash_name
  if target then
    table.insert(cmd, target)
  end

  table.insert(cmd, "--")

  local paths = {}
  if item.path then
    table.insert(paths, item.path)
  end
  vim.list_extend(paths, item.paths or {})
  vim.list_extend(cmd, paths)

  return require("thetto.util.git").diff(item.git_root, bufnr, cmd)
end

function M.open_diff(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = require("thetto.util.git").diff_buffer()
    local promise = M.render_diff(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto.vendor.promise").all(promises)
end

return M
