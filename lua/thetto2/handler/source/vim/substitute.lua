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

function M.collect(source_ctx)
  local bufnr = vim.api.nvim_get_current_buf()

  local items = {}
  local is_visual_mode = require("thetto2.vendor.misclib.visual_mode").is_current()
  for name, c in pairs(source_ctx.opts.commands) do
    local cmd_prefix = source_ctx.opts.range
    local row, end_row
    if is_visual_mode then
      local range = require("thetto2.lib.visual_mode").range()
      cmd_prefix = ("%d,%d"):format(range[1], range[2])
      row = range[1] - 1
      end_row = range[2]
    end

    local flags = c.flags
    if flags == nil then
      flags = source_ctx.opts.flags
    end

    local magic = c.magic
    if magic == nil then
      magic = source_ctx.opts.magic
    end

    local excmd = ("s/%s%s/%s/%s"):format(magic, c.pattern, c.after, flags)
    local desc = ("%s %s%s"):format(name, cmd_prefix, excmd)

    table.insert(items, {
      desc = desc,
      value = name,
      excmd = excmd,
      bufnr = bufnr,
      row = row,
      end_row = end_row,
      cmd_prefix = cmd_prefix,
      column_offsets = { excmd = #name + 1, value = 0 },
    })
  end
  return items
end

M.kind_name = "vim/substitute"

return M
