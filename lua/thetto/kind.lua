local util = require "thetto/util"

local action_prefix = "action_"
local M = {}
local base_kind = {}

base_kind.options = {move_to_input = {quit = false}, move_to_list = {quit = false}}

base_kind.action_move_to_input = function(_, state)
  vim.api.nvim_set_current_win(state.windows.input)
  vim.api.nvim_command("startinsert")
end

base_kind.action_move_to_list = function(_, state)
  vim.api.nvim_set_current_win(state.windows.list)
end

base_kind.action_quit = function(_, state)
  state.close({})
end

M.source_user_actions = {}
M.user_actions = {}

local wrap = function(raw_kind, kind_name)
  return {
    options = function(args)
      if raw_kind.options ~= nil and raw_kind.options[args.action] then
        return vim.tbl_extend("force", args, raw_kind.options[args.action])
      end
      return args
    end,
    find_action = function(action_name, default_action_name, source_name)
      local key
      if action_name == "default" and default_action_name ~= nil then
        key = default_action_name
      else
        key = action_prefix .. action_name
      end

      local source_action = M.source_user_actions[source_name]
      if source_action ~= nil and source_action[key] then
        return source_action[key]
      end

      local kind_action = M.user_actions[kind_name]
      if kind_action ~= nil and kind_action[key] then
        return kind_action[key]
      end

      return raw_kind[key]
    end,
  }
end

M.find = function(name, action_name)
  local kind
  local kind_name
  if base_kind[action_prefix .. action_name] ~= nil then
    kind = base_kind
    kind_name = "base"
  else
    kind = util.find_kind(name)
    kind_name = name
  end
  return wrap(kind, kind_name)
end

return M
