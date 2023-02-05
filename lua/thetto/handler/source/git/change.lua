local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  commit_hash = nil,
}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "diff", "--name-only" }
  local commit_hash = source_ctx.opts.commit_hash
  if commit_hash then
    table.insert(cmd, ("%s^...%s"):format(commit_hash, commit_hash))
  end
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local abs_path = pathlib.join(git_root, output)
    return {
      value = output,
      path = abs_path,
      commit_hash = commit_hash,
      git_root = git_root,
    }
  end, { cwd = git_root })
end

M.kind_name = "git/commit"

M.behaviors = {
  cwd = require("thetto.util.cwd").project(),
}

return M
