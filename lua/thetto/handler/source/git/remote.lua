local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err then
    return err
  end

  local cmd = { "git", "remote", "--verbose" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    return {
      value = output,
      git_root = git_root,
    }
  end, { cwd = git_root })
end

M.kind_name = "git/remote"

M.cwd = require("thetto.util.cwd").project()

return M
