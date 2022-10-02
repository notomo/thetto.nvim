local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "config", "--show-scope", "--show-origin", "--list" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local scope, path, value = output:match("(%S+)%s+(%S+)%s+(.*)")
    path = path:sub(#"file:" + 1)
    if scope == "local" then
      path = require("thetto.lib.path").join(git_root, path)
    end
    return {
      value = value,
      path = path,
      config = {
        scope = scope,
      },
    }
  end)
end

M.kind_name = "file"

return M
