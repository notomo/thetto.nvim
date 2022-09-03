local M = {}

M.opts = {
  max_depth = 100,
  to_absolute = function(_, path)
    return path
  end,
  modify_path = function(path)
    return path .. "/"
  end,
}

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

function M.collect(source_ctx)
  return require("thetto.handler.source.file.recursive").collect(source_ctx)
end

M.kind_name = "file/directory"

return M
