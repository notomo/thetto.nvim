local vim = vim

local M = {}

local to_texts = function(stage_ctx, ignorecase)
  local input = stage_ctx.input
  if ignorecase then
    input = stage_ctx.input:lower()
  end
  return vim
    .iter(vim.split(input, "%s"))
    :filter(function(text)
      return text ~= ""
    end)
    :totable()
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
  local texts = to_texts(stage_ctx, ignorecase)

  local to_field = opts.to_field
  local inversed = opts.inversed
  local filtered = vim
    .iter(items)
    :map(function(item)
      local field = to_field(item, stage_ctx)
      if ignorecase then
        field = field:lower()
      end

      for _, text in ipairs(texts) do
        if (field:find(text, 1, true) ~= nil) == inversed then
          return
        end
      end

      return item
    end)
    :totable()
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
    local offset = to_offset(item, stage_ctx)
    if item.desc and not offset then
      return
    end

    local field = to_field(item, stage_ctx)
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
