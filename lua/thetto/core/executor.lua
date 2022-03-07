local Kind = require("thetto.core.kind")
local listlib = require("thetto.lib.list")

local Executor = {}
Executor.__index = Executor

function Executor.new(default_kind_name, default_action_opts, default_action_name, execute_opts)
  vim.validate({
    default_kind_name = { default_kind_name, "string" },
    default_action_opts = { default_action_opts, "table" },
    default_action_name = { default_action_name, "string", true },
    execute_opts = { execute_opts, "table" },
  })
  local tbl = {
    default_action_name = default_action_name,
    execute_opts = execute_opts,
    _default_action_opts = default_action_opts,
    _default_kind_name = default_kind_name,
  }
  return setmetatable(tbl, Executor)
end

function Executor._action(self, action_name, kind_name, items, action_opts)
  local kind, err = Kind.new(self, kind_name)
  if err ~= nil then
    return nil, err
  end

  local name
  if action_name == "default" and self.default_action_name ~= nil then
    name = self.default_action_name
  else
    name = action_name
  end

  local opts = vim.tbl_extend("force", self._default_action_opts, action_opts or {})

  local action, action_err = kind:find_action(name, opts)
  if action_err ~= nil then
    return nil, action_err
  end

  return function(ctx)
    if action.behavior.quit then
      ctx.ui:close()
    end
    return action:execute(items, ctx)
  end,
    nil
end

function Executor.action(self, items, ctx, action_name, action_opts)
  vim.validate({
    items = { items, "table" },
    ctx = { ctx, "table" },
    action_name = { action_name, "string" },
    action_opts = { action_opts, "table", true },
  })

  local item_kind_pairs = {}
  for _, item in ipairs(items) do
    local kind_name = item.kind_name or self._default_kind_name
    local kind, err = Kind.new(self, kind_name)
    if err ~= nil then
      return nil, err
    end
    table.insert(item_kind_pairs, { item, kind:action_kind_name(action_name) })
  end
  if #item_kind_pairs == 0 then
    table.insert(item_kind_pairs, { {}, "base" })
  end

  local groups = listlib.group_by(item_kind_pairs, function(pair)
    return pair[2]
  end)

  local actions = {}
  for _, item_group in ipairs(groups) do
    local kind_name, item_pairs = unpack(item_group)
    local grouped_items = vim.tbl_map(function(pair)
      return pair[1]
    end, item_pairs)
    local action, err = self:_action(action_name, kind_name, grouped_items, action_opts)
    if err ~= nil then
      return nil, err
    end
    table.insert(actions, action)
  end

  local result
  for _, action in ipairs(actions) do
    local r, err = action(ctx)
    if err ~= nil then
      return nil, err
    end
    result = r
  end
  return result, nil
end

function Executor.actions(self, items, ctx, main_action_name, fallback_action_names, action_opts)
  vim.validate({
    fallback_action_names = { fallback_action_names, "table" },
  })
  local action_result, action_err = self:action(items, ctx, main_action_name, action_opts)
  if not action_err then
    return action_result, nil
  end
  if not vim.startswith(action_err, "not found action:") then
    return nil, action_err
  end

  local errs = { action_err }
  for _, action_name in ipairs(fallback_action_names) do
    local result, err = self:action(items, ctx, action_name, action_opts)
    if not err then
      return result, nil
    end
    table.insert(errs, err)
    if not vim.startswith(err, "not found action:") then
      break
    end
  end
  return nil, table.concat(errs, ", ")
end

function Executor.auto(self, ctx, action_name)
  vim.validate({ action_name = { action_name, "string", true } })

  if action_name == nil then
    return function() end
  end

  return function(items)
    local _, err = self:action(items, ctx, action_name, self._default_action_opts)
    return err
  end
end

return Executor
