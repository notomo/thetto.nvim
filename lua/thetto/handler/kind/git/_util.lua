local M = {}

function M.render_diff(bufnr, item)
  local cmd = { "git", "--no-pager", "show", "--date=iso" }
  local target = item.commit_hash or item.stash_name
  if target then
    table.insert(cmd, target)
  end
  if item.path then
    vim.list_extend(cmd, { "--", item.path })
  end
  return require("thetto.util.git").diff(bufnr, cmd)
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
