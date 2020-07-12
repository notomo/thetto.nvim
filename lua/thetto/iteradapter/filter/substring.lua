local M = {}

M.apply = function(items, line)
  local filtered = {}
  local texts = vim.split(line, "%s")
  for _, item in ipairs(items) do
    local ok = true
    for _, text in ipairs(texts) do
      if not item.value:find(text) then
        ok = false
        break
      end
    end

    if ok then
      table.insert(filtered, item)
    end
  end
  return filtered
end

return M
