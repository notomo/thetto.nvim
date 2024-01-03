local filelib = require("thetto2.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "config", "--show-scope", "--show-origin", "--list" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local scope, path, value = output:match("(%S+)%s+(%S+)%s+(.*)")
    path = path:sub(#"file:" + 1)
    if scope == "local" then
      path = vim.fs.joinpath(git_root, path)
    end
    return {
      value = value,
      path = path,
      config = {
        scope = scope,
      },
    }
  end, { cwd = git_root })
end

M.kind_name = "file"

M.behaviors = {
  cwd = require("thetto.util.cwd").project(),
}

return M
