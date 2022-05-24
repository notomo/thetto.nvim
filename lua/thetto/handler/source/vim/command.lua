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

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoVimCommandDefinition",
    start_key = "definition",
  },
})

M.kind_name = "vim/command"

return M
