local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

function M.collect(_, source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "status", "--short" }
  return require("thetto.util").job.run(cmd, source_ctx, function(output)
    local status, path = unpack(vim.split(vim.trim(output), "%s+"))
    local abs_path = pathlib.join(git_root, path)
    local kind_name
    if not filelib.readable(abs_path) then
      kind_name = "word"
    end
    local value = ("%2s %s"):format(status, path)
    return {
      value = value,
      path = abs_path,
      kind_name = kind_name,
    }
  end, { cwd = git_root })
end

M.kind_name = "file"

return M
