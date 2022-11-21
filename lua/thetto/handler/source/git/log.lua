local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  paths = {},
}

function M.collect(source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = {
    "git",
    "--no-pager",
    "log",
    "--pretty=format:%h %s <%an>%d",
    "--",
    unpack(source_ctx.opts.paths),
  }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local commit_hash = output:match("^(%S+) ")
    if not commit_hash then
      return nil
    end
    return {
      value = output,
      commit_hash = commit_hash,
      column_offsets = {
        commit_hash = 0,
      },
    }
  end)
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Character",
    end_column = 8,
  },
})

M.kind_name = "git/commit"

return M
