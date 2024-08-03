--- @class ThettoComplete
--- @field _all_items table
local M = {}
M.__index = M

function M.new()
  local tbl = {
    _all_items = {},
  }
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto.core.consumer_events")

local handlers = {
  --- @param self ThettoComplete
  [consumer_events.all.items_changed] = function(self, items, _)
    self._all_items = items
  end,
  --- @param self ThettoComplete
  [consumer_events.all.source_completed] = function(self)
    vim.schedule(function()
      vim.cmd.startinsert()
      vim.fn.complete(
        vim.fn.col("."),
        vim
          .iter(self._all_items)
          :map(function(item)
            return {
              word = item.value,
              menu = item.kind_name,
            }
          end)
          :totable()
      )
    end)
  end,
  [consumer_events.all.source_error] = function(_, err)
    vim.notify(require("thetto.vendor.misclib.message").wrap(err), vim.log.levels.WARN)
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

function M.get_items(self)
  return self._all_items
end

return M
