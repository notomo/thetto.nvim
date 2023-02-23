local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = {
    "git",
    "--no-pager",
    "log",
    "--diff-filter=D",
    "--summary",
    "--pretty=format:%h %s",
  }
  local commit_hash, message
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    if not vim.startswith(output, " ") then
      commit_hash, message = output:match("^(%S+) (.*)")
      return nil
    end
    local path = output:match("delete mode %S+ (.*)")
    return {
      value = ("%s %s %s"):format(commit_hash, message, path),
      path = path,
      commit_hash = commit_hash,
      git_root = git_root,
      column_offsets = {
        commit_hash = 0,
        message = #commit_hash + 1,
        path = #commit_hash + 1 + #message + 1,
      },
    }
  end, { cwd = git_root })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "message",
  },
  {
    group = "Label",
    start_key = "path",
  },
})

M.kind_name = "git/commit"

M.behaviors = {
  insert = false,
  cwd = require("thetto.util.cwd").project(),
}

return M
