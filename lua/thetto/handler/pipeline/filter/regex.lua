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

local is_ignorecase = require("thetto.util.filter").is_ignorecase

function M.apply(stage_ctx, items, opts)
  local highlight = function(...)
    M.highlight(stage_ctx, opts, ...)
  end

  if stage_ctx.input == "" then
    return items, highlight
  end

  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local regexes = to_regexes(stage_ctx, ignorecase)

  local filtered = {}
  local to_field = opts.to_field
  local inversed = opts.inversed
  for _, item in ipairs(items) do
    local field = to_field(item, stage_ctx)
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
  return filtered, highlight
end

local highlight_opts = {
  priority = vim.highlight.priorities.user - 1,
}

local MAX_COUNT_PER_REGEX_IN_LINE = 100

function M.highlight(stage_ctx, opts, decorator, items, first_line)
  if opts.inversed or stage_ctx.input == "" then
    return
  end

  local regexes = to_regexes(stage_ctx)
  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local to_field = opts.to_field
  local to_offset = opts.to_offset
  for i, item in ipairs(items) do
    local offset = to_offset(item, stage_ctx)
    if item.desc and not offset then
      return
    end

    local field = to_field(item, stage_ctx)
    if ignorecase then
      field = field:lower()
    end

    local positions = {}
    for _, regex in ipairs(regexes) do
      local str = field
      local index = 0
      for _ = 0, MAX_COUNT_PER_REGEX_IN_LINE, 1 do
        local s, e = regex:match_str(str)
        if s and e - s > 0 then
          table.insert(positions, { index + s, index + e })
        else
          break
        end
        str = str:sub(e + 1)
        index = index + e
      end
    end

    for _, pos in ipairs(positions) do
      decorator:highlight("Boolean", first_line + i - 1, offset + pos[1], offset + pos[2], highlight_opts)
    end
  end
end

M.opts = {
  smartcase = true,
  ignorecase = false,
  inversed = false,
  to_field = function(item, _)
    return item.value
  end,
  to_offset = function(item, _)
    local offsets = item.column_offsets or {}
    return offsets.value or 0
  end,
}

M.is_filter = true

return M
