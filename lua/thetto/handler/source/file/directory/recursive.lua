local M = {}

M.opts = { max_depth = 100 }

if vim.fn.has("win32") == 1 then
  M.opts.get_command = function(path, _)
    return { "cmd.exe", "/C", "dir", "/AD", "/B", "/S", path }
  end
else
  M.opts.get_command = function(path, max_depth)
    return {
      "find",
      "-L",
      path,
      "-maxdepth",
      max_depth,
      "-type",
      "d",
      "-name",
      ".git",
      "-prune",
      "-o",
      "-type",
      "d",
      "-print",
    }
  end
end

function M.collect(self, source_ctx)
  return require("thetto.handler.source.file.recursive").collect(self, source_ctx)
end

M.kind_name = "file/directory"

function M._modify_path(_, path)
  return path .. "/"
end

return M
