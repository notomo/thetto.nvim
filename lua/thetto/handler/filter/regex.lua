local M = {}

local to_regexes = function(filter_ctx)
  local line = filter_ctx.input_line
  if filter_ctx.ignorecase then
    line = filter_ctx.input_line:lower()
  end
  local texts = vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(line, "%s"))

  local regexes = {}
  for _, text in ipairs(texts) do
    local ok, regex = pcall(vim.regex, text)
    if ok then
      table.insert(regexes, regex)
    end
  end
  return regexes
end

function M.apply(self, filter_ctx, items)
  if filter_ctx.input_line == "" then
    return items
  end

  local filtered = {}
  local regexes = to_regexes(filter_ctx)
  for _, item in ipairs(items) do
    local value = self:to_value(item)
    if filter_ctx.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, regex in ipairs(regexes) do
      if (regex:match_str(value) ~= nil) == self.inversed then
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

vim.api.nvim_set_hl(0, "ThettoFilterRegexMatch", { default = true, link = "Boolean" })

function M.highlight(self, filter_ctx, _, first_line, items, highlighter)
  if self.inversed or filter_ctx.input_line == "" then
    return
  end

  local regexes = to_regexes(filter_ctx)
  for i, item in ipairs(items) do
    local offsets = item.column_offsets or {}
    if item.desc ~= nil and offsets[self.key] == nil then
      return
    end

    local value = self:to_value(item)
    if filter_ctx.ignorecase then
      value = value:lower()
    end

    local positions = {}
    for _, regex in ipairs(regexes) do
      local s, e = regex:match_str(value)
      if s ~= nil and e - s > 0 then
        table.insert(positions, { s, e })
      end
    end

    local offset = offsets[self.key] or 0
    for _, pos in ipairs(positions) do
      highlighter:add("ThettoFilterRegexMatch", first_line + i - 1, offset + pos[1], offset + pos[2])
    end
  end
end

return M
