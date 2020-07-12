local util = require "thetto/util"

local action_prefix = "action_"
local M = {}
local base_kind = {}

base_kind.options = {
  move_to_filter = {quit = false},
  move_to_list = {quit = false}
}

base_kind.action_move_to_filter = function(_, state)
  vim.api.nvim_set_current_win(state.windows.filter)
  vim.api.nvim_command("startinsert")
end

base_kind.action_move_to_list = function(_, state)
  vim.api.nvim_set_current_win(state.windows.list)
end

local wrap = function(raw_kind)
  return {
    options = function(args)
      if raw_kind.options ~= nil and raw_kind.options[args.action] then
        return vim.tbl_extend("force", args, raw_kind.options[args.action])
      end
      return args
    end,
    find_action = function(name)
      return raw_kind[action_prefix .. name]
    end
  }
end

M.find = function(name, action_name)
  local kind
  if base_kind[action_prefix .. action_name] ~= nil then
    kind = base_kind
  else
    kind = util.find_kind(name)
  end
  return wrap(kind)
end

return M
