local M = {}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local cmd = { "whereis", pattern }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      on_exit = function() end,
    })
    :next(function(output)
      local outputs = vim.split(output, " ", { plain = true })
      outputs = vim.list_slice(outputs, 2)
      return vim.tbl_map(function(path)
        local kind_name
        if vim.fn.isdirectory(path) ~= 0 then
          kind_name = "file/directory"
        end
        return {
          value = path,
          path = path,
          kind_name = kind_name,
        }
      end, outputs)
    end)
end

M.kind_name = "file"

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "String",
    filter = function(item)
      return item.kind_name == "file/directory"
    end,
  },
})

M.filters = require("thetto.util.filter").prepend("interactive")

return M
