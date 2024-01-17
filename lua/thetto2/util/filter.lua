local M = {}

function M.by_name(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.filter." .. name)
  if not origin then
    error("not found filter: " .. name)
  end

  local filter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  filter.name = filter.name or name
  if vim.tbl_get(filter, "opts", "inversed") then
    filter.name = "-" .. filter.name
  end
  return filter
end

function M.item(f)
  return {
    apply = function(_, items, _)
      return vim.iter(items):filter(f):totable()
    end,
    ignore_input = true,
  }
end

function M.is_ignorecase(ignorecase, smartcase, input)
  local case_sensitive = not ignorecase and smartcase and input:find("[A-Z]")
  return not case_sensitive
end

function M.relative_path(item_key, name, fields)
  local pathlib = require("thetto2.lib.path")
  local default_fields = {
    name = ("substring:%s:relative"):format(item_key),
    opts = {
      to_field = function(item, stage_ctx)
        return pathlib.to_relative(item[item_key], stage_ctx.cwd)
      end,
      to_offset = function(item, _)
        local offsets = item.column_offsets or {}
        return offsets[item_key] or 0
      end,
    },
  }
  local extended_fields = vim.tbl_deep_extend("force", default_fields, fields or {})
  return require("thetto2.util.filter").by_name(name, extended_fields)
end

return M
