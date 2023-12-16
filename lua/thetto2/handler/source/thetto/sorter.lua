local M = {}

function M.collect()
  return vim
    .iter(require("thetto.core.items.sorter").all())
    :map(function(e)
      return {
        value = e.name,
        path = e.path,
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
