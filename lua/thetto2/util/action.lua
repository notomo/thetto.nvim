local listlib = require("thetto2.vendor.misclib.collection.list")

local M = {}

function M.by_name(action_name, items, default_kind_name)
  action_name = action_name or "default"

  local item_kind_pairs = {}
  for _, item in ipairs(items) do
    local kind_name = default_kind_name or item.kind_name
    local kind = require("thetto2.core.kind").new(kind_name)
    table.insert(item_kind_pairs, { item, kind:action_kind_name(action_name) })
  end

  local groups = listlib.group_by_adjacent(item_kind_pairs, function(pair)
    return pair[2]
  end)

  local action_item_groups = {}
  for _, item_group in ipairs(groups) do
    local kind_name, item_pairs = unpack(item_group)
    local grouped_items = vim.tbl_map(function(pair)
      return pair[1]
    end, item_pairs)

    local kind = require("thetto2.core.kind").new(kind_name)
    local action = kind:find_action(action_name)
    table.insert(action_item_groups, {
      items = grouped_items,
      action = action,
    })
  end

  return action_item_groups
end

function M.call(kind_name, action_name, items, action_opts)
  local action_item_groups = M.by_name(action_name, items, kind_name)
  return require("thetto2.core.executor").execute(action_item_groups, action_opts)
end

return M
