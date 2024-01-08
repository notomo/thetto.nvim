local M = {}

function M.collect()
  local excmds = vim.api.nvim_get_commands({ builtin = false })
  excmds = vim.tbl_extend("force", excmds, vim.api.nvim_buf_get_commands(0, {}))

  return vim
    .iter(excmds)
    :map(function(_, excmd)
      if type(excmd) ~= "table" then
        return
      end
      return {
        desc = ("%s %s"):format(excmd.name, excmd.definition):gsub("%c+", " "),
        value = excmd.name,
        column_offsets = { value = 0, definition = #excmd.name + 1 },
      }
    end)
    :totable()
end

vim.api.nvim_set_hl(0, "ThettoVimCommandDefinition", { default = true, link = "Comment" })

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "ThettoVimCommandDefinition",
    start_key = "definition",
  },
})

M.kind_name = "vim/command"

return M
