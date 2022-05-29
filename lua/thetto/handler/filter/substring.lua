local vim = vim

local M = {}

local to_texts = function(filter_ctx)
  local line = filter_ctx.input_line
  if filter_ctx.ignorecase then
    line = filter_ctx.input_line:lower()
  end
  return vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(line, "%s"))
end

function M.apply(self, filter_ctx, items)
  if filter_ctx.input_line == "" then
    return items
  end

  local filtered = {}
  local texts = to_texts(filter_ctx)
  for _, item in ipairs(items) do
    local value = self:to_value(item)
    if filter_ctx.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      if (value:find(text, 1, true) ~= nil) == self.inversed then
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

vim.api.nvim_set_hl(0, "ThettoFilterSubstringMatch", { default = true, link = "Boolean" })

function M.highlight(self, filter_ctx, bufnr, first_line, items)
  if self.inversed or filter_ctx.input_line == "" then
    return
  end

  local highlighter = self.highlights:create(bufnr)
  local texts = to_texts(filter_ctx)
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
    for _, text in ipairs(texts) do
      local s
      local e = 0
      repeat
        s, e = value:find(text, e + 1, true)
        if s ~= nil then
          table.insert(positions, { s, e })
        end
      until s == nil
    end

    local offset = offsets[self.key] or 0
    for _, pos in ipairs(positions) do
      highlighter:add("ThettoFilterSubstringMatch", first_line + i - 1, offset + pos[1] - 1, offset + pos[2])
    end
  end
end

return M
