local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "status" }
  local states = {
    ["Changes to be committed:"] = "staged",
    ["Changes not staged for commit:"] = "unstaged",
    ["Untracked files:"] = "untracked",
  }
  local stage_parser = function(target)
    local status, path = target:match("([:^]+)%s+(.*)")
    return path, status == "new file"
  end
  local parsers = {
    staged = stage_parser,
    unstaged = stage_parser,
    untracked = function(target)
      return target, false
    end,
  }
  local index_status = "staged"
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local changed_state = states[output]
    if changed_state then
      index_status = changed_state
      return nil
    end

    local target = output:match("\t(.*)")
    if not target then
      return nil
    end

    local path = parsers[index_status](target)
    local abs_path = pathlib.join(git_root, path)
    local kind_name
    if not filelib.readable(abs_path) then
      kind_name = "word"
    end

    local status = ("%-9s"):format(index_status:upper())
    local desc = ("%s %s"):format(status, path)
    return {
      value = path,
      desc = desc,
      path = abs_path,
      index_status = index_status,
      kind_name = kind_name,
      column_offsets = {
        value = #status + 1,
      },
    }
  end, { cwd = git_root })
end

M.kind_name = "git/status"

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
})

return M
