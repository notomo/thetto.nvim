local pathlib = require("thetto2.lib.path")

local M = {}

local PREFIX = "■ "
local PREFIX_LENGTH = #PREFIX

M.opts = {
  args = { 0 },
}

function M.collect(source_ctx)
  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local bufnr, opts = unpack(source_ctx.opts.args)
  return vim
    .iter(vim.diagnostic.get(bufnr, opts))
    :map(function(diagnostic)
      if not vim.api.nvim_buf_is_valid(diagnostic.bufnr) then
        return
      end

      local path = vim.api.nvim_buf_get_name(diagnostic.bufnr)
      local relative_path = to_relative(path)
      local message = diagnostic.message:gsub("\n", " ")
      local desc = ("%s %s [%s:%s]"):format(relative_path, PREFIX .. message, diagnostic.source, diagnostic.code)
      return {
        value = message,
        desc = desc,
        row = diagnostic.lnum + 1,
        column = diagnostic.col,
        end_column = diagnostic.end_col,
        path = path,
        severity = diagnostic.severity,
        column_offsets = {
          path = 0,
          prefix = #relative_path + 1,
          value = #relative_path + 1 + PREFIX_LENGTH,
        },
      }
    end)
    :totable()
end

local hl_groups = {
  [vim.diagnostic.severity.ERROR] = "DiagnosticError",
  [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
  [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
  [vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    end_key = "prefix",
  },
  {
    group = function(item)
      return hl_groups[item.severity]
    end,
    start_key = "prefix",
    end_key = "value",
  },
})

M.kind_name = "file"

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").fields({
    {
      name = "value",
      field_name = "row",
    },
    {
      name = "value",
      field_name = "severity",
    },
  }),
})

return M
