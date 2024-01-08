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

  if item.path and target then
    -- fallback for renamed file path
    return require("thetto2.util.git").exists(item.git_root, target, item.path):next(function(ok)
      if ok then
        table.insert(cmd, item.path)
      end
      return require("thetto2.util.git").diff(item.git_root, bufnr, cmd)
    end)
  end
  return require("thetto2.util.git").diff(item.git_root, bufnr, cmd)
end

function M.open_diff(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = require("thetto2.util.git").diff_buffer()
    local promise = M.render_diff(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto2.vendor.promise").all(promises)
end

function M.open(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local promise = require("thetto2.util.git").content(item.git_root, item.path, item.commit_hash):next(function(path)
      f(path)
    end)
    table.insert(promises, promise)
  end
  return require("thetto2.vendor.promise").all(promises)
end

return M
