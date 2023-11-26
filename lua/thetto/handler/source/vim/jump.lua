local pathlib = require("thetto.lib.path")

local M = {}

M.opts = { per_file = false }

function M.collect(source_ctx)
  local home = pathlib.home()
  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local current_path = vim.api.nvim_buf_get_name(0)
  local jumps = vim.fn.reverse(vim.fn.getjumplist(0)[1])
  return vim
    .iter(jumps)
    :map(function(jump)
      local bufnr = jump.bufnr
      if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
      end
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.fn.bufload(bufnr)
      end

      local path = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
      if source_ctx.opts.per_file and (path == current_path or path == "") then
        return
      end
      current_path = path

      local line = vim.api.nvim_buf_get_lines(bufnr, jump.lnum - 1, jump.lnum, false)[1]
      if not line then
        return
      end

      local name = to_relative(path)
      local row = jump.lnum
      local label = ("%s:%d"):format(name:gsub(home, "~"), row)
      local desc = ("%s %s"):format(label, line)

      return {
        desc = desc,
        value = line,
        path = path,
        row = row,
        bufnr = bufnr,
        column = jump.col,
        column_offsets = { ["path:relative"] = 0, value = #label + 1 },
      }
    end)
    :totable()
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
