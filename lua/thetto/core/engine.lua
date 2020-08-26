local kinds = require "thetto/core/kind"
local repository = require "thetto/core/repository"
local listlib = require "thetto/lib/list"

local M = {}

-- TODO move other module
M.execute = function(action_name, range, action_opts, opts)
  local ctx
  if opts.resume then
    ctx = repository.resume()
    ctx.ui:update_offset(opts.offset)
  else
    local err
    ctx, err = repository.get_from_path()
    if err ~= nil then
      return nil, "not found state: " .. err
    end
  end

  local collector = ctx.collector
  local source_name = collector.source.name
  local ui = ctx.ui

  local selected_items = ui:selected_items(action_name, range)
  local item_groups = listlib.group_by(selected_items, function(item)
    return item.kind_name or collector.source.kind_name
  end)
  if #item_groups == 0 then
    table.insert(item_groups, {collector.source.kind_name, {}})
  end

  local actions = {}
  for _, item_group in ipairs(item_groups) do
    local kind_name, items = unpack(item_group)
    local kind, err = kinds.create(source_name, kind_name)
    if err ~= nil then
      return nil, err
    end

    local action, _action_opts, behavior, action_err = kinds.find_action(kind, vim.tbl_extend("force", ctx.action_opts, action_opts), action_name, collector.opts.action, source_name)
    if action_err ~= nil then
      return nil, action_err
    end
    kind.action_opts = _action_opts

    table.insert(actions, function()
      if behavior.quit then
        ui:close()
      end
      return action(kind, items, ctx)
    end)
  end

  local result
  for _, action in ipairs(actions) do
    local r, err = action()
    if err ~= nil then
      return nil, err
    end
    result = r
  end
  return result, nil
end

return M
