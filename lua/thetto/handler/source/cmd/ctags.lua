local filelib = require("thetto.lib.file")

local vim = vim

local M = {}

M.opts = { ignore = {} }

function M.collect(self, source_ctx)
  local file_path = vim.api.nvim_buf_get_name(0)
  if not filelib.readable(file_path) then
    return {}, nil
  end

  local cmd = { "ctags", "--output-format=xref", "-f", "-", file_path }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local value, typ, row, path, line = output:match("(%S+)%s+(%S+)%s+(%d+)%s+(%S+)%s+(.+)")
        if vim.tbl_contains(self.opts.ignore, typ) then
          goto continue
        end
        local _desc = ("%s [%s]"):format(value, typ)
        local desc = ("%s %s"):format(_desc, line)
        table.insert(items, {
          desc = desc,
          value = value,
          path = path,
          row = tonumber(row),
          column_offsets = { value = 0, line = #_desc, type = #value + 1 },
        })
        ::continue::
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = source_ctx.cwd,
  })

  return {}, job
end

vim.api.nvim_set_hl(0, "ThettoCtagsType", { default = true, link = "Statement" })
vim.api.nvim_set_hl(0, "ThettoCtagsLine", { default = true, link = "Comment" })

M.highlight = require("thetto.util").highlight.columns({
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

M.sorters = { "row" }

return M
