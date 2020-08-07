local jobs = require("thetto/lib/job")
local highlights = require("thetto/view/highlight")
local modulelib = require("thetto/lib/module")
local filter_core = require("thetto/core/base_filter")
local custom = require("thetto/custom")

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

  local source_action = custom.source_actions[source_name]
  if source_action ~= nil and source_action[key] then
    return source_action[key], opts, nil
  end

  local kind_action = custom.kind_actions[kind.name]
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
  add_filter = {quit = false},
  remove_filter = {quit = false},
}

local base_action_opts = {
  yank = {key = "value", register = "+"},
  append = {key = "value", type = ""},
  add_filter = {name = "substring"},
  remove_filter = {name = nil},
}

M.create = function(source_name, kind_name, action_name, args)
  local origin = modulelib.find_kind(kind_name)
  if origin == nil then
    return nil, nil, "not found kind: " .. kind_name
  end
  origin.__index = origin

  local kind = {}
  kind.name = kind_name

  local source_user_opts = {}
  if custom.source_actions ~= nil and custom.source_actions[source_name] ~= nil then
    source_user_opts = custom.source_actions[source_name].opts or {}
  end
  local user_opts = {}
  if custom.kind_actions ~= nil and custom.kind_actions[kind_name] ~= nil then
    user_opts = custom.kind_actions[kind_name].opts or {}
  end
  kind.opts = vim.tbl_extend("force", base_action_opts, origin.opts or {}, user_opts, source_user_opts)

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

  kind.action_yank = function(self, items)
    for _, item in ipairs(items) do
      local value = item[self.action_opts.key]
      vim.fn.setreg(self.action_opts.register, value)
      print("yank: " .. value)
    end
  end

  kind.action_append = function(self, items)
    for _, item in ipairs(items) do
      vim.api.nvim_put({item[self.action_opts.key]}, self.action_opts.type, true, true)
    end
  end

  kind.action_add_filter = function(self, _, state)
    local filter_name = self.action_opts.name
    local _, err = filter_core.create(filter_name)
    if err ~= nil then
      return nil, err
    end

    vim.api.nvim_buf_set_lines(state.buffers.input, -1, -1, false, {""})
    vim.api.nvim_win_set_height(state.windows.input, #state.buffers.filters + 1)

    local filter_names = vim.deepcopy(state.buffers.filters)
    table.insert(filter_names, filter_name)

    state:update_filters(filter_names)
  end

  kind.action_remove_filter = function(self, _, state)
    if #state.buffers.filters == 1 then
      return nil, "the last filter cannot be removed"
    end

    local cursor = vim.api.nvim_win_get_cursor(state.windows.input)
    local filter_name = self.action_opts.name or state.buffers.filters[cursor[1]]
    local _, err = filter_core.create(filter_name)
    if err ~= nil then
      return nil, err
    end

    local removed_index = nil
    local filter_names = {}
    for i, name in ipairs(state.buffers.filters) do
      if filter_name == name then
        removed_index = i
      else
        table.insert(filter_names, name)
      end
    end

    local lines = vim.api.nvim_buf_get_lines(state.buffers.input, 0, -1, false)
    table.remove(lines, removed_index)

    vim.api.nvim_buf_set_lines(state.buffers.input, 0, -1, false, lines)
    vim.api.nvim_win_set_height(state.windows.input, #state.buffers.filters - 1)

    state:update_filters(filter_names)
  end

  local opts = args
  if base_options[action_name] then
    opts = vim.tbl_extend("force", args, base_options[action_name])
  end

  return setmetatable(kind, origin), opts, nil
end

M.actions = function(kind_name, source_name)
  local kind = M.create(source_name, kind_name, "", {})
  if kind == nil then
    return {}
  end

  local names = {}
  local add_name = function(key)
    if vim.startswith(key, action_prefix) then
      local name = key:gsub("^" .. action_prefix, "")
      table.insert(names, name)
    end
  end

  for key in pairs(kind) do
    add_name(key)
  end

  for key in pairs(getmetatable(kind)) do
    add_name(key)
  end

  local source_action = custom.source_actions[source_name] or {}
  for key in pairs(source_action) do
    add_name(key)
  end

  local kind_action = custom.kind_actions[kind_name] or {}
  for key in pairs(kind_action) do
    add_name(key)
  end

  return names
end

return M
