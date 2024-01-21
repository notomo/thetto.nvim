local listlib = require("thetto.vendor.misclib.collection.list")
local Kind = require("thetto.core.kind")

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

  local kind_cache = {}
  local item_kind_pairs = vim
    .iter(items)
    :map(function(item)
      local kind_name = default_kind_name or item.kind_name

      local kind = kind_cache[kind_name]
      if not kind then
        kind = Kind.by_name(kind_name, opts.actions)
        kind_cache[kind_name] = kind
      end

      return {
        item = item,
        kind_name = Kind.action_kind_name(kind, action_name),
      }
    end)
    :totable()

  local groups = listlib.group_by_adjacent(item_kind_pairs, function(pair)
    return pair.kind_name
  end)

  local action_item_groups = vim
    .iter(groups)
    :map(function(item_group)
      local kind_name, item_pairs = unpack(item_group)
      local kind = Kind.by_name(kind_name, opts.actions)
      local action = Kind.find_action(kind, action_name)
      if not action then
        return nil
      end

      return {
        action = action,
        items = vim
          .iter(item_pairs)
          :map(function(pair)
            return pair.item
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
  return require("thetto.core.executor").execute(action_item_groups, action_opts)
end

function M.preview(kind_name, item, action_ctx)
  local kind = Kind.by_name(kind_name)
  return Kind.get_preview(kind, item, action_ctx)
end

return M
