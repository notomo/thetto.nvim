local M = {}

function M.by_name(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter." .. name)
  if not origin then
    error("not found sorter: " .. name)
  end

  local sorter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  sorter.name = name
  return sorter
end

function M.field_convert(name, fields)
  local origin = require("thetto2.vendor.misclib.module").find("thetto2.handler.pipeline.sorter.field._" .. name)
  if not origin then
    error("not found field sorter convert: " .. name)
  end
  local convert = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  convert.name = name
  return convert
end

function M.field_by_name(name, reversed)
  return require("thetto2.util.sorter").by_name("field", {
    desc = name,
    opts = {
      converts = {
        require("thetto2.util.sorter").field_convert("value", {
          opts = {
            to_field = function(item)
              return item[name]
            end,
          },
          reversed = reversed,
        }),
      },
    },
  })
end

function M.field_length_by_name(name, reversed)
  return require("thetto2.util.sorter").by_name("field", {
    desc = ("%s:length"):format(name),
    opts = {
      converts = {
        require("thetto2.util.sorter").field_convert("length", {
          opts = {
            to_field = function(item)
              return item[name]
            end,
            reversed = reversed,
          },
        }),
      },
    },
  })
end

function M.fields(converts)
  return require("thetto2.util.sorter").by_name("field", {
    desc = vim
      .iter(converts)
      :map(function(convert)
        return ("%s:%s"):format(convert.name, convert.field_name)
      end)
      :join(","),
    opts = {
      converts = vim.iter(converts):map(function(convert)
        return require("thetto2.util.sorter").field_convert(convert.name, {
          opts = {
            to_field = function(item)
              return item[convert.field_name]
            end,
          },
          reversed = convert.reversed,
        })
      end),
    },
  })
end

return M
