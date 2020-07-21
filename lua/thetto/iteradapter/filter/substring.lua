local M = {}

M.apply = function(items, input_line, opts)
  local line = input_line
  if opts.ignorecase then
    line = input_line:lower()
  end

  local filtered = {}
  local texts = vim.split(line, "%s")
  for _, item in ipairs(items) do
    local value = item.value
    if opts.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      local escaped = text:gsub("([^%w])", "%%%1")
      if not value:find(escaped) then
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
