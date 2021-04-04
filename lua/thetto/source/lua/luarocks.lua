local M = {}

M._find_dir = function(name, paths)
  for _, p in ipairs(paths) do
    local path = p:gsub("?", name)
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.filereadable(path) ~= 0 or (vim.endswith(dir, name) and vim.fn.isdirectory(dir) ~= 0) then
      return dir
    end
  end

  -- HACK
  if vim.startswith(name, "lua-") then
    return M._find_dir(name:gsub("^lua%-", ""), paths)
  end

  -- HACK
  if name:find("%-") then
    local splitted = vim.split(name, "-", true)
    return M._find_dir(splitted[1], paths)
  end

  return nil
end

M.collect = function(self, opts)
  local package_paths = vim.split(package.path, ";", true)
  vim.list_extend(package_paths, vim.split(package.cpath, ";", true))

  local job = self.jobs.new({"luarocks", "list", "--porcelain"}, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local factors = vim.split(output, "%s+")
        local name = factors[1]
        local version = factors[2]
        local path = self.pathlib.join(factors[4], name, version)

        local source_path = M._find_dir(name, package_paths)
        path = source_path or path

        local desc = ("%s %s"):format(name, version)
        table.insert(items, {
          value = name,
          path = path,
          desc = desc,
          version = version,
          column_offsets = {value = 0, version = #name + 1},
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

vim.cmd("highlight default link ThettoLuaLuarocksVersion Comment")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoLuaLuarocksVersion", i - 1, item.column_offsets.version, -1)
  end
end

M.kind_name = "directory"

return M
