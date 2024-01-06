--- @class ThettoPipeline
local M = {}
M.__index = M

function M.new(stages)
  local tbl = {
    _stages = stages,
  }
  return setmetatable(tbl, M)
end

function M.apply(self, pipeline_ctx, items)
  local highlights = {}
  for i, stage in ipairs(self._stages) do
    local stage_ctx = {
      input = pipeline_ctx.inputs[i] or "",
    }
    local new_items, highlight = stage.apply(stage_ctx, items, stage.opts)
    items = new_items
    if highlight then
      table.insert(highlights, highlight)
    end
  end

  local pipeline_highlight = function(...)
    for _, highlight in ipairs(highlights) do
      highlight(...)
    end
  end

  return items, pipeline_highlight
end

function M.filters(self)
  return vim
    .iter(self._stages)
    :filter(function(stage)
      return stage.is_filter
    end)
    :totable()
end

function M.has_source_input(self)
  return vim.iter(self._stages):any(function(stage)
    return stage.is_source_input
  end)
end

return M
