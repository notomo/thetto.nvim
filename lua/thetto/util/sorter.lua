local M = {}

function M.by_name(name, fields)
  local origin = require("thetto.vendor.misclib.module").find("thetto.handler.pipeline.sorter." .. name)
  if not origin then
    error("not found sorter: " .. name)
  end

  local sorter = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  sorter.name = name
  return sorter
end

function M.field_convert(name, fields)
  local origin = require("thetto.vendor.misclib.module").find("thetto.handler.pipeline.sorter.field._" .. name)
  if not origin then
    error("not found field sorter convert: " .. name)
  end
  local convert = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  convert.name = name
  return convert
end

local make_to_field = function(name)
  if type(name) == "table" then
    return function(item)
      return vim.tbl_get(item, unpack(name))
    end
  end
  return function(item)
    return item[name]
  end
end

local make_desc_name = function(name, reversed)
  local reverse_sign = reversed and "-" or ""
  if type(name) == "table" then
    return reverse_sign .. table.concat(name, ".")
  end
  return reverse_sign .. name
end

function M.field_by_name(name, reversed)
  local to_field = make_to_field(name)
  return require("thetto.util.sorter").by_name("field", {
    desc = make_desc_name(name, reversed),
    opts = {
      converts = {
        require("thetto.util.sorter").field_convert("value", {
          opts = {
            to_field = to_field,
          },
          reversed = reversed,
        }),
      },
    },
  })
end

function M.field_length_by_name(name, reversed)
  local to_field = make_to_field(name)
  return require("thetto.util.sorter").by_name("field", {
    desc = ("%s:length"):format(make_desc_name(name, reversed)),
    opts = {
      converts = {
        require("thetto.util.sorter").field_convert("length", {
          opts = {
            to_field = to_field,
            reversed = reversed,
          },
        }),
      },
    },
  })
end

function M.fields(converts)
  return require("thetto.util.sorter").by_name("field", {
    desc = vim
      .iter(converts)
      :map(function(convert)
        return ("%s:%s"):format(convert.name, make_desc_name(convert.field_name, convert.reversed))
      end)
      :join(","),
    opts = {
      converts = vim.iter(converts):map(function(convert)
        local to_field = make_to_field(convert.field_name)
        return require("thetto.util.sorter").field_convert(convert.name, {
          opts = {
            to_field = to_field,
          },
          reversed = convert.reversed,
        })
      end),
    },
  })
end

return M
