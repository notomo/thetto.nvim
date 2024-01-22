local M = {}
M.__index = M

function M.new()
  local tbl = {}
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto.core.consumer_events")

local handlers = {
  [consumer_events.all.source_error] = function(_, err)
    vim.notify(err, vim.log.levels.WARN)
  end,
}

function M.consume(self, event_name, ...)
  local handler = handlers[event_name]
  if not handler then
    return
  end
  return handler(self, ...)
end

local actions = {}
function M.call(self, action_name)
  local action = actions[action_name]
  if not action then
    return
  end
  return action(self)
end

function M.get_items(_)
  return {}
end

return M
