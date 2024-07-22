local pathlib = require("thetto.lib.path")

local M = {}

function M.collect()
  local home = pathlib.home()
  return vim
    .iter(vim.api.nvim_list_runtime_paths())
    :map(function(path)
      local value = path:gsub(home, "~")
      return {
        value = value,
        path = path,
      }
    end)
    :totable()
end

M.kind_name = "file/directory"

return M
