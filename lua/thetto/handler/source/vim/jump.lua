local pathlib = require("thetto.lib.path")

local M = {}

M.opts = { per_file = false }

function M.collect(self, source_ctx)
  local items = {}

  local jumps = vim.fn.reverse(vim.fn.getjumplist(0)[1])
  local home = pathlib.home()
  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local current_path = vim.api.nvim_buf_get_name(0)
  for _, jump in ipairs(jumps) do
    local bufnr = jump.bufnr
    if bufnr == 0 then
      bufnr = vim.api.nvim_get_current_buf()
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end

    local path = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
    if self.opts.per_file and (path == current_path or path == "") then
      goto continue
    end
    current_path = path

    local line = vim.api.nvim_buf_get_lines(bufnr, jump.lnum - 1, jump.lnum, false)[1] or ""
    local name = to_relative(path)
    local row = jump.lnum
    local label = ("%s:%d"):format(name:gsub(home, "~"), row)
    local desc = ("%s %s"):format(label, line)

    table.insert(items, {
      desc = desc,
      value = line,
      path = path,
      row = row,
      bufnr = bufnr,
      column = jump.col,
      column_offsets = { ["path:relative"] = 0, value = #label + 1 },
    })

    ::continue::
  end

  return items
end

vim.api.nvim_set_hl(0, "ThettoVimJumpPath", { default = true, link = "Comment" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoVimJumpPath",
    end_key = "value",
  },
})

M.kind_name = "position"

return M
