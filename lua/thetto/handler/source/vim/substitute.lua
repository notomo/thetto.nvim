local M = {}

M.opts = {
  flags = "ge",
  range = "%",
  magic = "\\v",
  commands = {
    remove_new_line = { pattern = "^$\\n", after = "" },
    clean_tab_sequence = { pattern = "\\\\t", after = "    " },
    clean_new_line_sequence = { pattern = "\\\\n", after = "\\r" },
    escape = { pattern = "^(.+)$", after = '\\=escape(submatch(0), "\\/")' },
    surround_by_single_quote = { pattern = "^(.+)$", after = "'\\1'" },
    surround_by_double_quote = { pattern = "^(.+)$", after = '"\\1"' },
  },
}

function M.collect(self, source_ctx)
  local bufnr = vim.api.nvim_get_current_buf()

  local items = {}
  for name, c in pairs(self.opts.commands) do
    local cmd_prefix = self.opts.range
    local range = nil
    if source_ctx.range ~= nil then
      cmd_prefix = ("%d,%d"):format(source_ctx.range.first, source_ctx.range.last)
      range = source_ctx.range
    end

    local flags = c.flags
    if flags == nil then
      flags = self.opts.flags
    end

    local magic = c.magic
    if magic == nil then
      magic = self.opts.magic
    end

    local excmd = ("s/%s%s/%s/%s"):format(magic, c.pattern, c.after, flags)
    local desc = ("%s %s%s"):format(name, cmd_prefix, excmd)

    table.insert(items, {
      desc = desc,
      value = name,
      excmd = excmd,
      bufnr = bufnr,
      range = range,
      range_part = cmd_prefix,
      column_offsets = { excmd = #name + 1, value = 0 },
    })
  end
  return items
end

M.kind_name = "vim/substitute"

return M
