local filelib = require("thetto.lib.file")

local M = {}

M.opts = { merged = false }

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "tag", "-l" }
  if source_ctx.opts.merged then
    table.insert(cmd, "--merged")
  end

  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    return {
      value = output,
      git_root = git_root,
    }
  end, { cwd = git_root })
end

M.kind_name = "git/tag"

M.cwd = require("thetto.util.cwd").project()

return M
