local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  commit_hash = nil,
  paths = {},
}

local status_mapping = {
  A = "add",
  D = "delete",
  M = "modify",
  R = "rename",
}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "diff", "--name-status" }
  local commit_hash = source_ctx.opts.commit_hash
  if commit_hash then
    table.insert(cmd, ("%s^...%s"):format(commit_hash, commit_hash))
  end
  vim.list_extend(cmd, { "--", unpack(source_ctx.opts.paths) })

  return require("thetto.util.job").start(cmd, source_ctx, function(output)
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

    local abs_path = pathlib.join(git_root, path)
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

M.kind_name = "git/commit"

M.behaviors = {
  cwd = require("thetto.util.cwd").project(),
}

return M
