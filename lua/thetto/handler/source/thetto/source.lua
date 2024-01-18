local M = {}

local get_all_source = function()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/source/**/*.lua", true)
  local already = {}

  local all = {}
  for _, path in ipairs(paths) do
    local source_file =
      vim.split(require("thetto.lib.path").adjust_sep(path), "lua/thetto/handler/source/", { plain = true })[2]
    local name = source_file:sub(1, #source_file - 4)
    local ignored = vim.startswith(vim.fs.basename(source_file), "_")
    if not ignored and not already[name] then
      local source_info = {
        name = name,
        path = path,
      }
      table.insert(all, source_info)
      already[name] = source_info
    end
  end

  for _, name in ipairs(require("thetto.core.source").registered_names()) do
    if not already[name] then
      table.insert(all, {
        name = name,
      })
    end
  end

  return all
end

function M.collect()
  return vim
    .iter(get_all_source())
    :map(function(e)
      return {
        value = e.name,
        path = e.path,
      }
    end)
    :totable()
end

M.kind_name = "thetto/source"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_length_by_name("value"),
})

return M
