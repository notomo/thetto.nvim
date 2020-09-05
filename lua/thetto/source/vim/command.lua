local M = {}

M.collect = function()
  local excmds = vim.api.nvim_get_commands({builtin = false})
  excmds = vim.tbl_extend("force", excmds, vim.api.nvim_buf_get_commands(0, {}))

  local items = {}
  for _, excmd in pairs(excmds) do
    if type(excmd) ~= "table" then
      goto continue
    end
    local desc = ("%s %s"):format(excmd.name, excmd.definition)
    table.insert(items, {
      desc = desc,
      value = excmd.name,
      column_offsets = {value = 0, definition = #excmd.name + 1},
    })
    ::continue::
  end
  return items
end

vim.api.nvim_command("highlight default link ThettoVimCommandDefinition Comment")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoVimCommandDefinition", i - 1, item.column_offsets.definition, -1)
  end
end

M.kind_name = "vim/command"

return M
