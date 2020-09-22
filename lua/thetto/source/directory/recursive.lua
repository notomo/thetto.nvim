local M = {}

if vim.fn.has("win32") == 1 then
  M.get_command = function(path, _)
    return {"cmd.exe", "/C", "dir", "/AD", "/B", "/S", path}
  end
else
  M.get_command = function(path, max_depth)
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

M.collect = function(self, opts)
  return require("thetto/source/file/recursive").collect(self, opts)
end

M.kind_name = "directory"

M._modify_path = function(self, path)
  return self.pathlib.adjust_sep(path) .. "/"
end

return M
