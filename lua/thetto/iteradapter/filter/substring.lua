local M = {}

local to_texts = function(input_line, opts)
  local line = input_line
  if opts.ignorecase then
    line = input_line:lower()
  end

  local texts = {}
  for _, text in ipairs(vim.split(line, "%s")) do
    if text == "" then
      goto continue
    end
    local escaped = text:gsub("([^%w])", "%%%1")
    table.insert(texts, escaped)
    ::continue::
  end
  return texts
end

M.apply = function(items, input_line, opts)
  local filtered = {}
  local texts = to_texts(input_line, opts)
  for _, item in ipairs(items) do
    local value = item.value
    if opts.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      if not value:find(text) then
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

M.highlight = function(bufnr, items, input_line, opts)
  local ns = vim.api.nvim_create_namespace("thetto-filter-substring-highlight")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local texts = to_texts(input_line, opts)
  for i, item in ipairs(items) do
    if item.desc ~= nil and item.value_start_col == nil then
      return
    end

    local value = item.value
    if opts.ignorecase then
      value = value:lower()
    end

    local positions = {}
    for _, text in ipairs(texts) do
      local s
      local e = 0
      repeat
        s, e = value:find(text, e + 1)
        if s ~= nil then
          table.insert(positions, {s, e})
        end
      until s == nil
    end

    local offset = item.value_start_col or 0
    for _, pos in ipairs(positions) do
      vim.api.nvim_buf_add_highlight(bufnr, ns, "Boolean", i - 1, offset + pos[1] - 1, offset + pos[2])
    end
  end
end

return M
