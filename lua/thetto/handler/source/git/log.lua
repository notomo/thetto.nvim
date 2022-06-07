local filelib = require("thetto.lib.file")

local M = {}

function M.collect(_, source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "log", "--date=short", "--pretty=format:%h %cd %s <%an>%d" }
  return require("thetto.util").job.start(cmd, source_ctx, function(output)
    local commit_hash, date = output:match("^(%S+) (%S+)")
    if not commit_hash then
      return nil
    end
    return {
      value = output,
      commit_hash = commit_hash,
      date = date,
      column_offsets = {
        commit_hash = 0,
        date = #commit_hash + 1,
      },
    }
  end)
end

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "Character",
    end_key = "date",
  },
  {
    group = "Label",
    start_key = "date",
    end_key = function(item)
      return item.column_offsets.date + #item.date
    end,
  },
})

M.kind_name = "git/commit"

return M
