local M = {}

function M.collect(self, opts)
  local items = {}

  local jumps = vim.fn.reverse(vim.fn.getjumplist(0)[1])
  local home = self.pathlib.home()
  local to_relative = self.pathlib.relative_modifier(opts.cwd)
  for _, jump in ipairs(jumps) do
    local bufnr = jump.bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end

    local line = vim.api.nvim_buf_get_lines(bufnr, jump.lnum - 1, jump.lnum, false)[1] or ""
    local path = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
    local name = to_relative(path)
    local row = jump.lnum
    local label = ("%s:%d"):format(name:gsub(home, "~"), row)
    local desc = ("%s %s"):format(label, line)

    table.insert(items, {
      desc = desc,
      value = line,
      path = path,
      row = row,
      bufnr = jump.bufnr,
      column = jump.col,
      column_offsets = {["path:relative"] = 0, value = #label + 1},
    })

    ::continue::
  end

  return items
end

vim.cmd("highlight default link ThettoVimJumpPath Comment")

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoVimJumpPath", first_line + i - 1, 0, item.column_offsets.value - 1)
  end
end

M.kind_name = "position"

return M
