local M = {}

M.apply = function(candidates, line)
  local filtered = {}
  local texts = vim.split(line, "%s")
  for _, candidate in ipairs(candidates) do
    local ok = true
    for _, text in ipairs(texts) do
      if not (candidate.value):find(text) then
        ok = false
        break
      end
    end

    if ok then
      table.insert(filtered, candidate)
    end
  end
  return filtered
end

return M
