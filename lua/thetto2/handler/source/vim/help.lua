local listlib = require("thetto2.lib.list")
local vim = vim

local M = {}

function M.collect()
  local items = {}

  local paths = vim.api.nvim_get_runtime_file("doc/tags", true)

  local pack_path = vim.split(vim.o.packpath, ",", { plain = true })[1]
  pack_path = vim.fn.fnamemodify(pack_path, ":p")
  local pattern = pack_path .. "pack/*/opt/*/doc/tags"
  vim.list_extend(paths, vim.fn.glob(pattern, false, true))

  paths = listlib.unique(paths)
  for _, tags_path in ipairs(paths) do
    local f = io.open(tags_path, "r")
    local doc_path = tags_path:gsub("tags$", "")
    for line in f:lines() do
      local splitted = vim.split(line, "\t")
      local tag = splitted[1]
      local path = splitted[2]
      local tag_pattern = splitted[3]:sub(2):gsub("%*", [[\*]])
      table.insert(items, { value = tag, path = doc_path .. path, pattern = tag_pattern })
    end
    f:close()
  end
  return items
end

M.kind_name = "vim/help"

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").field_length_by_name("value"),
})

return M
