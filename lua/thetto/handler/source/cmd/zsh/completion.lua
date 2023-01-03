local M = {}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local cmd = { "capture.zsh", pattern }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local desc = vim.fn.trim(output, "\n\r", 2)
    local value = vim.split(desc, "%s+")[1]
    return {
      value = value,
      desc = desc,
      column_offsets = {
        value = 0,
        desc = #value,
      },
    }
  end)
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "desc",
  },
})

M.kind_name = "word"

M.filters = require("thetto.util.filter").prepend("interactive")

return M
