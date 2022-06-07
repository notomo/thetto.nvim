local filelib = require("thetto.lib.file")

local M = {}

function M.collect(self, source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local to_items = function(data)
    local items = {}
    local outputs = require("thetto.lib.job").parse_output(data)
    for _, output in ipairs(outputs) do
      local commit_hash, date = output:match("^(%S+) (%S+)")
      table.insert(items, {
        value = output,
        commit_hash = commit_hash,
        date = date,
        column_offsets = {
          commit_hash = 0,
          date = #commit_hash + 1,
        },
      })
    end
    return items
  end

  local cmd = { "git", "--no-pager", "log", "--date=short", "--pretty=format:%h %cd %s <%an>%d" }

  return function(observer)
    local output_buffer = require("thetto.util.job.output_buffer").new()
    local job = self.jobs.new(cmd, {
      on_stdout = function(_, _, data)
        if not data then
          local str = output_buffer:pop()
          observer:next(to_items(str))
          observer:complete()
          return
        end

        local str = output_buffer:append(data)
        if not str then
          return
        end

        observer:next(to_items(str))
      end,
      stdout_buffered = false,
      stderr_buffered = false,
      cwd = source_ctx.cwd,
    })

    local start_err = job:start()
    if start_err then
      return observer:error(start_err)
    end

    return function()
      job:stop()
    end
  end
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
