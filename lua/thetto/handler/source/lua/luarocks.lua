local M = {}

function M._find_dir(name, paths)
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
  if vim.startswith(name, "lua_") then
    return M._find_dir(name:gsub("^lua_", ""), paths)
  end
  if vim.startswith(name, "lua") then
    return M._find_dir(name:gsub("^lua", ""), paths)
  end
  if name:find("%-") then
    local splitted = vim.split(name, "-", true)
    return M._find_dir(splitted[1], paths)
  end

  return nil
end

function M.collect(self, opts)
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

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoLuaLuarocksVersion", first_line + i - 1, item.column_offsets.version, -1)
  end
end

M.kind_name = "file/directory"

return M
