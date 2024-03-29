local filelib = require("thetto.lib.file")

local vim = vim

local M = {}

function M.collect(source_ctx)
  local file_path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
  if not filelib.readable(file_path) then
    return {}, nil
  end

  local cmd = { "ctags", "--output-format=xref", "-f", "-", file_path }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local value, typ, row, path, line = output:match("(%S+)%s+(%S+)%s+(%d+)%s+(%S+)%s+(.+)")
    local _desc = ("%s [%s]"):format(value, typ)
    local desc = ("%s %s"):format(_desc, line)
    return {
      desc = desc,
      value = value,
      path = path,
      row = tonumber(row),
      ctags_typ = typ,
      column_offsets = { value = 0, line = #_desc, type = #value + 1 },
    }
  end)
end

vim.api.nvim_set_hl(0, "ThettoCtagsType", { default = true, link = "Statement" })
vim.api.nvim_set_hl(0, "ThettoCtagsLine", { default = true, link = "Comment" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoCtagsType",
    start_key = "type",
    end_key = "line",
  },
  {
    group = "ThettoCtagsLine",
    start_key = "line",
  },
})

M.kind_name = "file"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_by_name("row"),
})

return M
