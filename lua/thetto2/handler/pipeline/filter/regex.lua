local M = {}

local to_regexes = function(stage_ctx, ignorecase)
  local input = stage_ctx.input
  if ignorecase then
    input = input:lower()
  end
  local texts = vim.tbl_filter(function(text)
    return text ~= ""
  end, vim.split(input, "%s"))

  local regexes = {}
  for _, text in ipairs(texts) do
    local ok, regex = pcall(vim.regex, text)
    if ok then
      table.insert(regexes, regex)
    end
  end
  return regexes
end

local is_ignorecase = require("thetto2.util.pipeline").is_ignorecase

function M.apply(stage_ctx, items, opts)
  if stage_ctx.input == "" then
    return items
  end

  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local regexes = to_regexes(stage_ctx, ignorecase)

  local filtered = {}
  local to_field = opts.to_field
  local inversed = opts.inversed
  for _, item in ipairs(items) do
    local field = to_field(item)
    if ignorecase then
      field = field:lower()
    end

    local ok = true
    for _, regex in ipairs(regexes) do
      if (regex:match_str(field) ~= nil) == inversed then
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
