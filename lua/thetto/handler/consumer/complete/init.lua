local vim = vim
local fn = vim.fn

--- @class ThettoComplete
--- @field _all_items table
--- @field _cursor_word {str:string,offset:integer}
--- @field _priorities table<string,integer>
--- @field _source_to_label table<string,string>
--- @field _is_manual boolean
local M = {}
M.__index = M

local default_opts = {
  priorities = {},
  source_to_label = {},
  is_manual = false,
}

function M.new(raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts)
  local tbl = {
    _all_items = {},
    _priorities = opts.priorities,
    _cursor_word = nil,
    _source_to_label = opts.source_to_label,
    _is_manual = opts.is_manual,
  }
  return setmetatable(tbl, M)
end

local consumer_events = require("thetto.core.consumer_events")

--- @param self ThettoComplete
local complete = function(self, items, cursor_word)
  self._all_items = items

  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "i" and mode ~= "ic" then
    return
  end

  if mode == "ic" and not vim.tbl_isempty(vim.v.completed_item) then
    return
  end

  if #items == 0 then
    return
  end

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
    .iter(items)
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
    if a.score == b.score then
      return a.item.value > b.item.value
    end
    return a.score > b.score
  end)

  local completion_items = vim
    .iter(scored_items)
    :map(function(c)
      return {
        word = c.item.has_edit and "" or c.item.value,
        abbr = c.item.desc,
        menu = c.item.kind_label or self._source_to_label[c.item.source_name] or c.item.source_name or c.item.kind_name,
        icase = 1,
        dup = 1,
        empty = 1,
        equal = c.item.has_edit and 1 or 0,
        user_data = {
          source_name = c.item.source_name,
          item = c.item.original_item,
          client_id = c.item.client_id,
        },
        abbr_hlgroup = c.item.deprecated and "DiagnosticDeprecated" or nil,
      }
    end)
    :totable()
  fn.complete(cursor_word.offset, completion_items)
end

local debounced_complete, cancel = require("thetto.lib.debounce").wrap(110, vim.schedule_wrap(complete))

local handlers = {
  --- @param self ThettoComplete
  [consumer_events.all.items_changed] = function(self, items, _)
    debounced_complete(self, items, self._cursor_word)
  end,
  [consumer_events.all.source_error] = function(_, err)
    require("thetto.lib.message").warn(err)
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

function M.apply(self, cursor_word)
  self._cursor_word = cursor_word
end

function M.cancel()
  cancel()
end

function M.get_items(self)
  return self._all_items
end

return M
