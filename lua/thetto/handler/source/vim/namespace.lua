local M = {}

function M.collect()
  return vim
    .iter(vim.api.nvim_get_namespaces())
    :map(function(name, id)
      local value = ("%2d: %s"):format(id, name)
      return {
        value = value,
        namespace = id,
      }
    end)
    :totable()
end

M.kind_name = "word"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_by_name("namespace"),
})

return M
