local M = {}

function M.default()
  return M.by_names({
    "filter.substring",
  })
end

function M.by_names(names)
  local stages = vim
    .iter(names)
    :map(function(name)
      return require("thetto2.handler.pipeline." .. name)
    end)
    :totable()
  return function()
    return require("thetto2.core.pipeline").new(stages)
  end
end

return M
