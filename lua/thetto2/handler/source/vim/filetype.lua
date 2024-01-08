local M = {}

function M.collect()
  local items = {}
  local names = vim.fn.getcompletion("*", "filetype")
  for _, name in ipairs(names) do
    table.insert(items, { value = name })
  end
  return items
end

M.kind_name = "word"

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").field_length_by_name("value"),
})

return M
