local vim = vim

local M = {}

local to_texts = function(stage_ctx, ignorecase)
  local input = stage_ctx.input
  if ignorecase then
    input = stage_ctx.input:lower()
  end
  return vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(input, "%s"))
end

local is_ignorecase = require("thetto2.util.pipeline").is_ignorecase

function M.apply(stage_ctx, items, opts)
  if stage_ctx.input == "" then
    return items
  end

  local filtered = {}
  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local texts = to_texts(stage_ctx, ignorecase)
  for _, item in ipairs(items) do
    local field = opts.to_field(item)
    if ignorecase then
      field = field:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      if (field:find(text, 1, true) ~= nil) == opts.inversed then
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
  smartcase = true,
  ignorecase = false,
  inversed = false,
  to_field = function(item)
    return item.value
  end,
}

return M
