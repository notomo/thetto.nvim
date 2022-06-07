local filelib = require("thetto.lib.file")

local M = {}

M.opts = { merged = false }

function M.collect(self, source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "tag", "-l" }
  if self.opts.merged then
    table.insert(cmd, "--merged")
  end

  return require("thetto.util").job.start(cmd, source_ctx, function(output)
    return {
      value = output,
    }
  end)
end

M.kind_name = "git/tag"

return M
