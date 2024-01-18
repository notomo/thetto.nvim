local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  commit_hash = nil,
  path = nil,
}

local status_mapping = {
  A = "add",
  D = "delete",
  M = "modify",
  R = "rename",
}

function M._to_item(git_root, commit_hash, output)
  local status_mark, path_parts = output:match("^(.)%S*%s+(.*)")
  local status = status_mapping[status_mark]

  local path = path_parts
  local rename_from = ""
  if status == "rename" then
    local parts = vim.split(path_parts, "%s+")
    path = parts[1]
    rename_from = (" <- %s"):format(parts[2])
  end
  local desc = ("%s %s%s"):format(status_mark, path, rename_from)

  local abs_path = vim.fs.joinpath(git_root, path)
  return {
    value = path,
    desc = desc,
    path = abs_path,
    commit_hash = commit_hash,
    status = status,
    git_root = git_root,
    column_offsets = {
      value = 2,
      rename_from = 2 + #path,
    },
  }
end

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "diff", "--name-status" }
  local commit_hash = source_ctx.opts.commit_hash
  if commit_hash then
    table.insert(cmd, ("%s^...%s"):format(commit_hash, commit_hash))
  end
  table.insert(cmd, "--")

  if commit_hash and source_ctx.opts.path then
    -- fallback for renamed file path
    return require("thetto.util.git").exists(git_root, commit_hash, source_ctx.opts.path):next(function(ok)
      if ok then
        table.insert(cmd, source_ctx.opts.path)
      end
      return require("thetto.util.job").start(cmd, source_ctx, function(output)
        return M._to_item(git_root, commit_hash, output)
      end, { cwd = git_root })
    end)
  end

  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    return M._to_item(git_root, commit_hash, output)
  end, { cwd = git_root })
end

local status_highlights = {
  add = "DiffAdd",
  delete = "DiffDelete",
  modify = "Comment",
  rename = "DiffChange",
}

M.highlight = require("thetto.util.highlight").columns({
  {
    group = function(item)
      return status_highlights[item.status]
    end,
    end_column = 1,
  },
  {
    group = "Comment",
    start_key = "rename_from",
  },
})

M.kind_name = "git/change"

M.cwd = require("thetto.util.cwd").project()

return M
