local M = {}

if vim.fn.has("win32") == 1 then
  function M.get_command(path, _)
    return {"cmd.exe", "/C", "dir", "/AD", "/B", "/S", path}
  end
else
  function M.get_command(path, max_depth)
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

M.opts = {max_depth = 100}

function M.collect(self, opts)
  return require("thetto/source/file/recursive").collect(self, opts)
end

M.kind_name = "directory"

function M._modify_path(_, path)
  return path .. "/"
end

return M
