local vim = vim

local M = {}

local to_texts = function(stage_ctx, opts)
  local input = stage_ctx.input
  if opts.ignorecase then
    input = stage_ctx.input:lower()
  end
  return vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(input, "%s"))
end

function M.apply(stage_ctx, items, opts)
  if stage_ctx.input == "" then
    return items
  end

  local filtered = {}
  local texts = to_texts(stage_ctx, opts)
  for _, item in ipairs(items) do
    local value = item.value
    if opts.ignorecase then
      value = value:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      if (value:find(text, 1, true) ~= nil) == opts.inversed then
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

M.opts = {
  ignorecase = false,
  inversed = false,
}

return M
