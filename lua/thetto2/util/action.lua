local listlib = require("thetto2.vendor.misclib.collection.list")

local M = {}

local grouping_default_opts = {
  actions = {
    opts = {},
    default_action = nil,
    -- action_... = function
  },
  action_name = "default",
  kind_name = nil,
}
function M.grouping(items, raw_opts)
  local opts = vim.tbl_deep_extend("force", grouping_default_opts, raw_opts or {})

  local action_name = opts.action_name or opts.actions.default_action
  local default_kind_name = opts.kind_name

  local item_kind_pairs = vim
    .iter(items)
    :map(function(item)
      local kind_name = default_kind_name or item.kind_name
      local kind = require("thetto2.core.kind").by_name(kind_name, opts.actions)
      return { item, kind:action_kind_name(action_name) }
    end)
    :totable()

  local groups = listlib.group_by_adjacent(item_kind_pairs, function(pair)
    return pair[2]
  end)

  local action_item_groups = vim
    .iter(groups)
    :map(function(item_group)
      local kind_name, item_pairs = unpack(item_group)
      local kind = require("thetto2.core.kind").by_name(kind_name, opts.actions)
      return {
        action = kind:find_action(action_name),
        items = vim
          .iter(item_pairs)
          :map(function(pair)
            return pair[1]
          end)
          :totable(),
      }
    end)
    :totable()

  return action_item_groups
end

function M.call(kind_name, action_name, items, action_opts)
  local action_item_groups = M.grouping(items, {
    action_name = action_name,
    kind_name = kind_name,
  })
  return require("thetto2.core.executor").execute(action_item_groups, action_opts)
end

return M
