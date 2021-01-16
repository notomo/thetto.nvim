local M = {}

M.collect = function(self, _)
  local git_root, err = self.filelib.find_git_root()
  if err ~= nil then
    return {}, nil, err
  end

  local cmd = {"git", "--no-pager", "status", "--short"}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local status, path = unpack(vim.split(vim.trim(output), "%s+"))
        local abs_path = self.pathlib.join(git_root, path)
        local kind_name
        if not self.filelib.readable(abs_path) then
          kind_name = "word"
        end
        local value = ("%2s %s"):format(status, path)
        table.insert(items, {value = value, path = abs_path, kind_name = kind_name})
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = git_root,
  })

  return {}, job
end

M.kind_name = "file"

return M
