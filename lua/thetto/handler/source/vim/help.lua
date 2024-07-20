local listlib = require("thetto.lib.list")
local vim = vim

local M = {}

function M.collect()
  local paths = vim.api.nvim_get_runtime_file("doc/tags", true)
  local pack_path = vim.split(vim.o.packpath, ",", { plain = true })[1]
  local pattern = vim.fs.joinpath(vim.fs.normalize(pack_path), "pack/*/opt/*/doc/tags")
  vim.list_extend(paths, vim.fn.glob(pattern, false, true))

  return vim
    .iter(listlib.unique(paths))
    :map(function(tags_path)
      local f = io.open(tags_path, "r")
      if not f then
        return nil
      end

      local doc_path = tags_path:gsub("tags$", "")
      local items = vim
        .iter(f:lines())
        :map(function(line)
          local splitted = vim.split(line, "\t")
          local tag = splitted[1]
          local path = splitted[2]
          local tag_pattern = [[\V\C]] .. splitted[3]:sub(2)
          return {
            value = tag,
            path = vim.fs.joinpath(doc_path, path),
            pattern = tag_pattern,
          }
        end)
        :totable()
      f:close()
      return items
    end)
    :flatten()
    :totable()
end

M.kind_name = "vim/help"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_length_by_name("value"),
})

return M
