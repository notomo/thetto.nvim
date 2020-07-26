local util = require("thetto/util")
local jobs = require("thetto/job")
local highlights = require("thetto/highlight")

local M = {}

local action_prefix = "action_"
M.find_action = function(kind, action_opts, action_name, default_action_name, source_name)
  local name
  if action_name == "default" and default_action_name ~= nil then
    name = default_action_name
  else
    name = action_name
  end
  if name == "default" then
    name = kind.default_action
  end

  local key = action_prefix .. name
  local opts = vim.tbl_extend("force", kind.opts[name] or {}, action_opts)

  local source_action = M.source_user_actions[source_name]
  if source_action ~= nil and source_action[key] then
    return source_action[key], opts, nil
  end

  local kind_action = M.user_actions[kind.name]
  if kind_action ~= nil and kind_action[key] then
    return kind_action[key], opts, nil
  end

  local action = kind[key]
  if action ~= nil then
    return action, opts, nil
  end

  return nil, nil, "not found action: " .. name
end

local base_options = {
  move_to_input = {quit = false},
  move_to_list = {quit = false},
  move_to_info = {quit = false},
  debug_print = {quit = false},
  toggle_selection = {quit = false},
  toggle_all_selection = {quit = false},
}

M.create = function(kind_name, action_name, args)
  local origin = util.find_kind(kind_name)
  if origin == nil then
    return nil, nil, "not found kind: " .. kind_name
  end
  origin.__index = origin

  local kind = {}
  kind.name = kind_name
  kind.opts = origin.opts or {}
  kind.default_action = origin.default_action or "echo"
  kind.jobs = jobs

  kind.action_toggle_selection = function(_, items, state)
    state:toggle_selections(items)
    highlights.update_selections(state.buffers.list, state.buffers.filtered)
  end

  kind.action_toggle_all_selection = function(_, _, state)
    state:toggle_selections(state.buffers.filtered)
    highlights.update_selections(state.buffers.list, state.buffers.filtered)
  end

  kind.action_move_to_input = function(_, _, state)
    vim.api.nvim_set_current_win(state.windows.input)
    vim.api.nvim_command("startinsert")
  end

  kind.action_move_to_list = function(_, _, state)
    vim.api.nvim_set_current_win(state.windows.list)
  end

  kind.action_move_to_info = function(_, _, state)
    vim.api.nvim_set_current_win(state.windows.info)
  end

  kind.action_quit = function(_, _, state)
    local resume = false
    local offset = 0
    state:close(resume, offset)
  end

  kind.action_debug_print = function(_, items)
    for _, item in ipairs(items) do
      print(vim.inspect(item))
    end
  end

  kind.action_echo = function(_, items)
    for _, item in ipairs(items) do
      print(item.value)
    end
  end

  local opts = args
  if base_options[action_name] then
    opts = vim.tbl_extend("force", args, base_options[action_name])
  end

  return setmetatable(kind, origin), opts, nil
end

M.actions = function(kind_name)
  local kind = util.find_kind(kind_name)
  if kind == nil then
    return {}
  end

  local names = {}
  for key in pairs(kind) do
    if vim.startswith(key, action_prefix) then
      local name = key:gsub("^" .. action_prefix, "")
      table.insert(names, name)
    end
  end
  return names
end

M.source_user_actions = {}
M.user_actions = {}

return M
