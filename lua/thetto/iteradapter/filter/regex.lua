local M = {}

local to_regexes = function(input_line, opts)
  local line = input_line
  if opts.ignorecase then
    line = input_line:lower()
  end
  local texts = vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(line, "%s"))

  return vim.tbl_map(function(text)
    return vim.regex(text)
  end, texts)
end

M.apply = function(self, items, input_line, opts)
  local filtered = {}
  local regexes = to_regexes(input_line, opts)
  for _, item in ipairs(items) do
    local value = self:to_value(item)
    if opts.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, regex in ipairs(regexes) do
      if (regex:match_str(value) ~= nil) == self.inverse then
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

M.highlight = function(self, bufnr, items, input_line, opts)
  if self.inverse then
    return
  end

  local ns = vim.api.nvim_create_namespace("thetto-filter-regex-highlight")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local regexes = to_regexes(input_line, opts)
  for i, item in ipairs(items) do
    local offsets = item.column_offsets or {}
    if item.desc ~= nil and offsets[self.key] == nil then
      return
    end

    local value = self:to_value(item)
    if opts.ignorecase then
      value = value:lower()
    end

    local positions = {}
    for _, regex in ipairs(regexes) do
      local s, e = regex:match_str(value)
      if s ~= nil and e - s > 0 then
        table.insert(positions, {s, e})
      end
    end

    local offset = offsets[self.key] or 0
    for _, pos in ipairs(positions) do
      vim.api.nvim_buf_add_highlight(bufnr, ns, "Boolean", i - 1, offset + pos[1], offset + pos[2])
    end
  end
end

return M