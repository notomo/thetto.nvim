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
  local highlight = function(...)
    M.highlight(stage_ctx, opts, ...)
  end

  if stage_ctx.input == "" then
    return items, highlight
  end

  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local texts = to_texts(stage_ctx, ignorecase)

  local filtered = {}
  local to_field = opts.to_field
  local inversed = opts.inversed
  for _, item in ipairs(items) do
    local field = to_field(item)
    if ignorecase then
      field = field:lower()
    end

    local ok = true
    for _, text in ipairs(texts) do
      if (field:find(text, 1, true) ~= nil) == inversed then
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

function M.highlight(stage_ctx, opts, decorator, items, first_line)
  if opts.inversed or stage_ctx.input == "" then
    return
  end

  local texts = to_texts(stage_ctx)
  local ignorecase = is_ignorecase(opts.ignorecase, opts.smartcase, stage_ctx.input)
  local to_field = opts.to_field
  local to_offset = opts.to_offset
  for i, item in ipairs(items) do
    local offset = to_offset(item)
    if item.desc and not offset then
      return
    end

    local field = to_field(item)
    if ignorecase then
      field = field:lower()
    end

    local positions = {}
    for _, text in ipairs(texts) do
      local s
      local e = 0
      repeat
        s, e = field:find(text, e + 1, true)
        if s then
          table.insert(positions, { s, e })
        end
      until s == nil
    end

    for _, pos in ipairs(positions) do
      decorator:highlight("Boolean", first_line + i - 1, offset + pos[1] - 1, offset + pos[2], highlight_opts)
    end
  end
end

M.opts = {
  smartcase = true,
  ignorecase = false,
  inversed = false,
  to_field = function(item)
    return item.value
  end,
  to_offset = function(item)
    local offsets = item.column_offsets or {}
    return offsets.value or 0
  end,
}

M.is_filter = true

return M
