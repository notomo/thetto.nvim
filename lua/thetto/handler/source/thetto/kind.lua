local M = {}

local get_all_kind = function()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/kind/**/*.lua", true)
  local already = {}
  local all = {}
  for _, path in ipairs(paths) do
    local kind_file =
      vim.split(require("thetto.lib.path").adjust_sep(path), "lua/thetto/handler/kind/", { plain = true })[2]
    local name = kind_file:sub(1, #kind_file - 4)
    local ignored = vim.startswith(vim.fs.basename(kind_file), "_")
    if not ignored and not already[name] then
      local kind_info = {
        name = name,
        path = path,
      }
      table.insert(all, kind_info)
      already[name] = kind_info
    end
  end

  for _, name in ipairs(require("thetto.core.kind").registered_names()) do
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
    .iter(get_all_kind())
    :map(function(e)
      return {
        value = e.name,
        path = e.path,
      }
    end)
    :totable()
end

M.kind_name = "file"

M.modify_pipeline = require("thetto.util.pipeline").append({
  require("thetto.util.sorter").field_length_by_name("value"),
})

return M
