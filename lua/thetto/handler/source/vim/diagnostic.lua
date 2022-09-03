local pathlib = require("thetto.lib.path")

local M = {}

local PREFIX = "■ "
local PREFIX_LENGTH = #PREFIX

M.opts = {
  args = { 0 },
}

function M.collect(source_ctx)
  local items = {}

  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local bufnr, opts = unpack(source_ctx.opts.args)
  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, opts)) do
    if not vim.api.nvim_buf_is_valid(diagnostic.bufnr) then
      goto continue
    end
    local path = vim.api.nvim_buf_get_name(diagnostic.bufnr)
    local relative_path = to_relative(path)
    local message = diagnostic.message:gsub("\n", " ")
    local desc = ("%s %s [%s:%s]"):format(relative_path, PREFIX .. message, diagnostic.source, diagnostic.code)
    table.insert(items, {
      value = message,
      desc = desc,
      row = diagnostic.lnum + 1,
      path = path,
      severity = diagnostic.severity,
      column_offsets = {
        path = 0,
        prefix = #relative_path + 1,
        value = #relative_path + 1 + PREFIX_LENGTH,
      },
    })
    ::continue::
  end
  return items
end

local hl_groups = {
  [vim.diagnostic.severity.ERROR] = "DiagnosticError",
  [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
  [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
  [vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

M.highlight = require("thetto.util.highlight").columns({
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
M.sorters = { "row", "numeric:severity" }

return M
