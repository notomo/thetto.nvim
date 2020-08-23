local kinds = require "thetto/core/kind"
local repository = require "thetto/core/repository"
local listlib = require "thetto/lib/list"

local M = {}

-- TODO move other module
M.execute = function(action_name, range, action_opts, args)
  local path = vim.api.nvim_buf_get_name(0)
  local source_name = path:match("thetto://(.+)/thetto")
  if source_name == nil then
    return nil, "not found source_name"
  end

  local ctx = repository.get(source_name)
  local collector = ctx.collector
  local ui = ctx.ui

  local selected_items = ui:selected_items(action_name, range, args.offset)
  local item_groups = listlib.group_by(selected_items, function(item)
    return item.kind_name or collector.source.kind_name
  end)

  local actions = {}
  local opts
  local i = 1
  repeat
    local kind_name, items
    if #item_groups == 0 then
      kind_name = collector.source.kind_name
      items = {}
    else
      kind_name, items = unpack(item_groups[i])
    end
    local kind, _opts, kind_err = kinds.create(source_name, kind_name, action_name, args)
    if kind_err ~= nil then
      return nil, kind_err
    end
    opts = _opts

    local action, _action_opts, action_err = kinds.find_action(kind, vim.tbl_extend("force", ctx.action_opts, action_opts), action_name, collector.opts.action, source_name)
    if action_err ~= nil then
      return nil, action_err
    end
    kind.action_opts = _action_opts

    table.insert(actions, function()
      return action(kind, items, ctx)
    end)

    i = i + 1
  until i > #item_groups

  if opts.quit then
    ui:close()
  end

  local result, action_err
  for _, action in ipairs(actions) do
    result, action_err = action()
  end
  return result, action_err
end

return M
