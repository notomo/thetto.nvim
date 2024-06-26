local M = {}

function M.get_pattern()
  return vim.fn.input("Pattern: ")
end

function M.collect(source_ctx)
  local pattern = source_ctx.pattern
  if pattern == "" then
    return {}
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
      return vim
        .iter(outputs)
        :map(function(path)
          local kind_name
          if vim.fn.isdirectory(path) ~= 0 then
            kind_name = "file/directory"
          end
          return {
            value = path,
            path = path,
            kind_name = kind_name,
          }
        end)
        :totable()
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

M.modify_pipeline = require("thetto.util.pipeline").prepend({
  require("thetto.util.filter").by_name("source_input"),
})

return M
