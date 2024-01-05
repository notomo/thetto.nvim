local M = {}

function M.default()
  return M.list({
    require("thetto2.handler.pipeline.filter.substring"),
  })
end

function M.list(stages)
  return function()
    return require("thetto2.core.pipeline").new(stages)
  end
end

return M
