local vim = vim
local fn = vim.fn

--- @class ThettoComplete
--- @field _all_items table
local M = {}
M.__index = M

local default_opts = {
  priorities = {},
  cursor_word = nil,
  source_to_label = {},
}

function M.new(raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts)
  local tbl = {
    _all_items = {},
    _priorities = opts.priorities,
    _cursor_word = opts.cursor_word,
    _source_to_label = opts.source_to_label,
  }
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto.core.consumer_events")

--- @param self ThettoComplete
local complete = function(self)
  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "i" then
    return
  end

  local cursor_word = self._cursor_word or require("thetto.lib.cursor").word(0) or {
    str = "",
    offset = 1,
  }
  local prefix = cursor_word.str

  local match = function(value)
    return fn.matchfuzzypos({ value }, prefix)[3][1]
  end
  if prefix == "" then
    match = function()
      return 0
    end
  end

  local scored_items = vim
    .iter(self._all_items)
    :map(function(item)
      local score = match(item.value)
      if not score then
        return nil
      end
      return {
        score = score + (self._priorities[item.source_name or ""] or 0),
        item = item,
      }
    end)
    :totable()
  table.sort(scored_items, function(a, b)
    return a.score > b.score
  end)

  local completion_items = vim
    .iter(scored_items)
    :map(function(c)
      return {
        word = c.item.value,
        menu = c.item.kind_label or self._source_to_label[c.item.source_name] or c.item.source_name or c.item.kind_name,
      }
    end)
    :totable()
  fn.complete(cursor_word.offset, completion_items)
end

local debounced_complete = require("thetto.vendor.misclib.debounce").wrap(10, vim.schedule_wrap(complete))

local handlers = {
  --- @param self ThettoComplete
  [consumer_events.all.items_changed] = function(self, items, _)
    self._all_items = items
    debounced_complete(self)
  end,
  --- @param self ThettoComplete
  [consumer_events.all.source_completed] = vim.schedule_wrap(function(self)
    debounced_complete(self)
  end),
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
