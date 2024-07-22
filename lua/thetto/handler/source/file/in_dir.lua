local M = {}

function M.collect(source_ctx)
  local paths = vim
    .iter(vim.fn.readdir(source_ctx.cwd))
    :map(function(path)
      return vim.fs.normalize(vim.fs.joinpath(source_ctx.cwd, path))
    end)
    :totable()

  table.sort(paths, function(a, b)
    local is_dir_a = vim.fn.isdirectory(a)
    local is_dir_b = vim.fn.isdirectory(b)
    if is_dir_a ~= is_dir_b then
      return is_dir_a > is_dir_b
    end
    return a < b
  end)

  return vim
    .iter(paths)
    :map(function(path)
      local value = vim.fs.basename(path)
      local kind_name = M.kind_name
      if vim.fn.isdirectory(path) ~= 0 then
        value = value .. "/"
        kind_name = "file/directory"
      end
      return {
        value = value,
        path = path,
        kind_name = kind_name,
      }
    end)
    :totable()
end

vim.api.nvim_set_hl(0, "ThettoFileInDirDirectory", { default = true, link = "String" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoFileInDirDirectory",
    filter = function(item)
      return item.kind_name == "file/directory"
    end,
  },
})

M.kind_name = "file"

return M
