local M = {}

function M.collect()
  local items = {}
  local count = vim.fn.histnr("cmd")
  for i = count, 1, -1 do
    local history = vim.fn.histget("cmd", i)
    if history ~= "" then
      table.insert(items, { value = history })
    end
  end
  return items
end

M.kind_name = "vim/command"

return M
