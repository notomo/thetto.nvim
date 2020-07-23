local kinds = require("thetto/kind")
local states = require "thetto/state"

local M = {}

M.action = function(_, _, _)
  local state, _ = states.get(0)
  if state == nil then
    return ""
  end

  local offset = 0
  local item = state.select_from_list(offset)
  if item == nil then
    return ""
  end

  local kind_name = item.kind_name or state.buffers.kind_name
  local names = kinds.actions(kind_name)
  return table.concat(names, "\n")
end

return M
