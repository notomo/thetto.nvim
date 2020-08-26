local jobs = require("thetto/lib/job")
local modulelib = require("thetto/lib/module")
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
  local behavior = vim.tbl_deep_extend("force", {quit = true}, kind.behaviors[name] or {})

  local source_action = custom.source_actions[source_name]
  if source_action ~= nil and source_action[key] then
    return source_action[key], opts, behavior, nil
  end

  local kind_action = custom.kind_actions[kind.name]
  if kind_action ~= nil and kind_action[key] then
    return kind_action[key], opts, behavior, nil
  end

  local action = kind[key]
  if action ~= nil then
    return action, opts, behavior, nil
  end

  return nil, nil, nil, "not found action: " .. name
end

local base_behaviors = {
  move_to_input = {quit = false},
  move_to_list = {quit = false},
  debug_print = {quit = false},
  toggle_selection = {quit = false},
  toggle_all_selection = {quit = false},
  add_filter = {quit = false},
  remove_filter = {quit = false},
  inverse_filter = {quit = false},
  change_filter = {quit = false},
  reverse_sorter = {quit = false},
  preview = {quit = false},
}

local base_action_opts = {
  yank = {key = "value", register = "+"},
  append = {key = "value", type = ""},
  add_filter = {name = "substring"},
  remove_filter = {name = nil},
  change_filter = {name = nil},
  reverse_sorter = {name = nil},
  move_to_input = {behavior = "i"},
}

M.create = function(source_name, kind_name)
  local origin = modulelib.find_kind(kind_name)
  if origin == nil then
    return nil, nil, "not found kind: " .. kind_name
  end
  origin.__index = origin

  local kind = {}
  kind.name = kind_name
  kind.behaviors = vim.tbl_deep_extend("force", base_behaviors, origin.behaviors or {})

  local source_user_opts = {}
  if custom.source_actions ~= nil and custom.source_actions[source_name] ~= nil then
    source_user_opts = custom.source_actions[source_name].opts or {}
  end
  local user_opts = {}
  if custom.kind_actions ~= nil and custom.kind_actions[kind_name] ~= nil then
    user_opts = custom.kind_actions[kind_name].opts or {}
  end
  kind.opts = vim.tbl_deep_extend("force", base_action_opts, origin.opts or {}, user_opts, source_user_opts)

  kind.default_action = origin.default_action or "echo"
  kind.jobs = jobs

  kind.action_toggle_selection = function(_, items, ctx)
    ctx.collector:toggle_selections(items)
  end

  kind.action_toggle_all_selection = function(_, _, ctx)
    ctx.collector:toggle_all_selections()
  end

  kind.action_move_to_input = function(self, _, ctx)
    ctx.ui:enter("input")
    ctx.ui:start_insert(self.action_opts.behavior)
  end

  kind.action_move_to_list = function(_, _, ctx)
    ctx.ui:enter("list")
    vim.api.nvim_command("stopinsert")
  end

  kind.action_quit = function(_, _, ctx)
    ctx.ui:close()
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

  kind.action_add_filter = function(self, _, ctx)
    local filter_name = self.action_opts.name
    ctx.collector:add_filter(filter_name)
  end

  kind.action_remove_filter = function(self, _, ctx)
    local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
    return nil, ctx.collector:remove_filter(filter_name)
  end

  kind.action_inverse_filter = function(self, _, ctx)
    local filter_name = self.action_opts.name or ctx.ui:current_position_filter().name
    ctx.collector:inverse_filter(filter_name)
  end

  kind.action_change_filter = function(self, _, ctx)
    local old_filter_name = ctx.ui:current_position_filter().name
    return nil, ctx.collector:change_filter(old_filter_name, self.action_opts.name)
  end

  kind.action_reverse_sorter = function(self, _, ctx)
    local sorter_name = self.action_opts.name or ctx.ui:current_position_sorter().name
    ctx.collector:reverse_sorter(sorter_name)
  end

  return setmetatable(kind, origin), nil
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
