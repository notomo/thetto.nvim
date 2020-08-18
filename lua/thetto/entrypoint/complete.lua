local kinds = require("thetto/core/kind")
local sources = require("thetto/core/source")
local states = require "thetto/core/state"

local M = {}

M.action = function(_, _, _)
  local state, _ = states.get(0)
  if state == nil then
    return ""
  end

  local action_name = nil
  local offset = 0
  local item = state:selected_items(action_name, {given = false}, offset)
  if item == nil then
    return ""
  end

  local kind_name = item.kind_name or state.buffers.kind_name
  local source_name = state.buffers.source_name
  local names = kinds.actions(kind_name, source_name)
  return table.concat(names, "\n")
end

M.source = function(_, _, _)
  local names = sources.names()
  return table.concat(names, "\n")
end

return M
