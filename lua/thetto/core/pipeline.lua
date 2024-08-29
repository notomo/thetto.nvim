--- @class ThettoPipelineStageContext
--- @field input string
--- @field cwd string

--- @class ThettoPipelineStage
--- @field ignore_input boolean?
--- @field is_source_input boolean?
--- @field apply fun(stage_ctx:ThettoPipelineStageContext,items:table[],opts:table?):(table[],fun())
--- @field opts table?

--- @class ThettoPipeline
--- @field _stages ThettoPipelineStage[]
local M = {}
M.__index = M

function M.new(stages)
  local tbl = {
    _stages = stages,
  }
  return setmetatable(tbl, M)
end

--- @param source_ctx ThettoSourceContext
function M.apply(self, source_ctx, items, inputs)
  local highlights = {}
  local input_index = 1
  for _, stage in ipairs(self._stages) do
    local input
    if stage.ignore_input then
      input = ""
    else
      input = inputs[input_index] or ""
      input_index = input_index + 1
    end

    local stage_ctx = {
      input = input,
      cwd = source_ctx.cwd,
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

function M.sorters(self)
  return vim
    .iter(self._stages)
    :filter(function(stage)
      return stage.is_sorter
    end)
    :totable()
end

function M.initial_source_input_pattern(self)
  local has_source_input = vim.iter(self._stages):any(function(stage)
    return stage.is_source_input
  end)

  if has_source_input then
    return ""
  end

  return nil
end

return M
