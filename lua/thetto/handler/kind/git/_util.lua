local M = {}

function M.to_git_root(items)
  return items[1].git_root
end

--- @async
function M.render_diff(bufnr, item)
  local cmd = { "git", "--no-pager", "show", "--date=iso" }

  local target = item.commit_hash or item.stash_name
  if target and item.commit_hash_to then
    table.insert(cmd, ("%s^...%s"):format(target, item.commit_hash_to))
  elseif target then
    table.insert(cmd, target)
  end

  table.insert(cmd, "--")

  if item.path and target then
    -- fallback for renamed file path
    if require("thetto.util.git").exists(item.git_root, target, item.path) then
      table.insert(cmd, item.path)
    end
  end
  return require("thetto.util.git").diff(item.git_root, bufnr, cmd)
end

--- @return vim.async.Task
--- @return table preview
function M.preview_diff(item)
  local bufnr = require("thetto.util.git").diff_buffer()
  --- @async
  local render = function()
    return M.render_diff(bufnr, item)
  end
  return vim.async.run(render), { raw_bufnr = bufnr }
end

--- @async
function M.open_diff(items, f)
  local fs = {}
  for _, item in ipairs(items) do
    local bufnr = require("thetto.util.git").diff_buffer()
    --- @async
    table.insert(fs, function()
      return M.render_diff(bufnr, item)
    end)
    f(bufnr)
  end
  return require("thetto.lib.async").all(fs)
end

--- @async
function M.open(items, f)
  local fs = vim
    .iter(items)
    :map(function(item)
      --- @async
      --- @return nil
      return function()
        local content = require("thetto.util.git").content(item.git_root, item.path, item.commit_hash)
        f(content.buffer_path)
      end
    end)
    :totable()
  return require("thetto.lib.async").all(fs)
end

return M
