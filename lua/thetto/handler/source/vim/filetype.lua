local M = {}

function M.collect()
  return vim
    .iter(vim.fn.getcompletion("*", "filetype"))
    :map(function(filetype)
      return { value = filetype }
    end)
    :totable()
end

M.kind_name = "word"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_length_by_name("value"),
})

return M
