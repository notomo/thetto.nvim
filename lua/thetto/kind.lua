local util = require("thetto/util")
local jobs = require("thetto/job")

local M = {}

local action_prefix = "action_"
M.find_action = function(kind, action_name, default_action_name, source_name)
  local key, name
  if action_name == "default" and default_action_name ~= nil then
    key = default_action_name
    name = default_action_name
  else
    key = action_prefix .. action_name
    name = action_name
  end

  local source_action = M.source_user_actions[source_name]
  if source_action ~= nil and source_action[key] then
    return source_action[key], nil
  end

  local kind_action = M.user_actions[kind.name]
  if kind_action ~= nil and kind_action[key] then
    return kind_action[key], nil
  end

  local action = kind[key]
  if action ~= nil then
    return action, nil
  end

  return nil, "not found action: " .. name
end

local base_options = {
  move_to_input = {quit = false},
  move_to_list = {quit = false},
  debug_print = {quit = false},
}

M.create = function(kind_name, action_name, args)
  local origin = util.find_kind(kind_name)
  if origin == nil then
    return nil, nil, "not found kind: " .. kind_name
  end
  origin.__index = origin

  local kind = {}
  kind.name = kind_name
  kind.jobs = jobs

  kind.action_move_to_input = function(_, _, state)
    vim.api.nvim_set_current_win(state.windows.input)
    vim.api.nvim_command("startinsert")
  end

  kind.action_move_to_list = function(_, _, state)
    vim.api.nvim_set_current_win(state.windows.list)
  end

  kind.action_quit = function(_, _, state)
    state.close({})
  end

  kind.action_debug_print = function(_, items)
    for _, item in ipairs(items) do
      print(vim.inspect(item))
    end
  end

  local opts = args
  if base_options[action_name] then
    opts = vim.tbl_extend("force", args, base_options[action_name])
  end

  return setmetatable(kind, origin), opts, nil
end

M.source_user_actions = {}
M.user_actions = {}

return M
