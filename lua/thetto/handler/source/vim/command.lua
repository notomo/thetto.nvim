local M = {}

function M.collect()
  local excmds = vim.api.nvim_get_commands({ builtin = false })
  excmds = vim.tbl_extend("force", excmds, vim.api.nvim_buf_get_commands(0, {}))

  local items = {}
  for _, excmd in pairs(excmds) do
    if type(excmd) ~= "table" then
      goto continue
    end
    table.insert(items, {
      desc = ("%s %s"):format(excmd.name, excmd.definition):gsub("%c+", " "),
      value = excmd.name,
      column_offsets = { value = 0, definition = #excmd.name + 1 },
    })
    ::continue::
  end
  return items
end

vim.cmd("highlight default link ThettoVimCommandDefinition Comment")

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoVimCommandDefinition", first_line + i - 1, item.column_offsets.definition, -1)
  end
end

M.kind_name = "vim/command"

return M
